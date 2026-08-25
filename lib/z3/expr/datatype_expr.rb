module Z3
  class DatatypeExpr < Expr
    # A field, as an expression of that field's own sort. Every datatype sort also
    # defines a method per field, so this is only needed for a field named after
    # something an expression already answers to - `l[:sort]` where `l.sort` is still
    # the sort.
    #
    # Accessors are total, the way Z3 makes them: `l.head` on a `nil` is some Int,
    # Z3 just doesn't say which.
    def [](field)
      sort.accessor(field)[self]
    end

    # Whether this is that constructor - `l.is?(:nil)`. Every datatype sort also
    # defines `is_nil`, and `nil?` too where that name is free.
    def is?(constructor_name)
      sort.recognizer(constructor_name)[self]
    end

    # A Symbol for a constructor with no fields, the way an enum value is one, and
    # otherwise the constructor name pointing at a Hash of its fields:
    #
    #   :nil
    #   {cons: {head: 10, tail: {cons: {head: 20, tail: :nil}}}}
    #
    # Which is the shape `DatatypeSort#from_const` reads back, so a value out of a
    # model goes straight into the next set of constraints.
    def value
      constructor_name = constructor_name_of(func_decl)
      fields = sort.constructors[constructor_name]
      return constructor_name if fields.empty?
      {constructor_name => fields.keys.zip(arguments).map { |field, arg| [field, field_value(field, arg)] }.to_h}
    end

    private

    # A term is a value when its own declaration is one of the constructors, which is
    # what anything out of a model will be. A variable, or an accessor applied to
    # something, isn't.
    def constructor_name_of(decl)
      sort.constructor_names.find { |constructor_name| sort.constructor(constructor_name).eql?(decl) } or
        raise Z3::Exception, "Can't convert #{self} into a Ruby value, it isn't built from #{sort.name}'s constructors"
    end

    def field_value(field, arg)
      # Bitvec has #signed_value and #unsigned_value, Real has #to_r and #to_f, and
      # neither has a #value to call - so the datatype can't have one either, and
      # saying which field stopped it is the whole difference between this and a
      # NoMethodError
      unless arg.respond_to?(:value)
        raise Z3::Exception, "Can't convert #{sort} into a Ruby value, field #{field.inspect} is #{arg.sort}, which has no #value"
      end
      arg.value
    end

    class << self
      # One subclass per datatype sort, holding that sort's recognizers and field
      # readers - the way Struct.new builds a class rather than defining methods on
      # every instance.
      #
      # Each constructor gets `is_nil`, which is what Z3's own documentation calls it
      # and is always available, plus `nil?` where Ruby doesn't already answer to that
      # name. `nil?` is exactly the case that has to be skipped - taking it over would
      # make every value of the sort look like Ruby's nil.
      #
      # Fields work the same way as a tuple's: a field named after something Expr
      # already answers to (`sort`, `value`, `to_s`) doesn't get a reader, and
      # `l[:value]` reads it regardless.
      def class_for(sort)
        Class.new(self) do
          sort.constructor_names.each do |constructor_name|
            define_method("is_#{constructor_name}") { is?(constructor_name) }
            predicate = "#{constructor_name}?"
            next if DatatypeExpr.method_defined?(predicate) or DatatypeExpr.private_method_defined?(predicate)
            define_method(predicate) { is?(constructor_name) }
          end
          sort.field_names.each do |field|
            next if DatatypeExpr.method_defined?(field) or DatatypeExpr.private_method_defined?(field)
            define_method(field) { self[field] }
          end
          # The class is anonymous, and Ruby names it `#<Class:0x000...>` in every
          # NoMethodError about a field that doesn't exist - which is the one message
          # these classes are most likely to turn up in
          define_singleton_method(:name) { "Z3::DatatypeExpr(#{sort.name})" }
          define_singleton_method(:inspect) { name }
        end
      end
    end

    public_class_method :new
  end
end
