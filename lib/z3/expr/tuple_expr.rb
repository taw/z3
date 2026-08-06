module Z3
  class TupleExpr < Expr
    # A field, as an expression of that field's own sort. Every tuple sort also defines
    # a method per field, so this is only needed for a field named after something an
    # expression already answers to - `t[:sort]` where `t.sort` is still the sort.
    def [](field)
      sort.accessor(field)[self]
    end

    # A Hash from field name to Ruby value, nested tuples included. Each field converts
    # itself, so this works on anything the fields can be reduced to literals in -
    # most usefully a value out of a model.
    def value
      sort.fields.keys.map { |field| [field, field_value(field)] }.to_h
    end

    private

    def field_value(field)
      field_expr = self[field]
      # Bitvec has #signed_value and #unsigned_value, Real has #to_r and #to_f, and
      # neither has a #value to call - so the tuple can't have one either, and saying
      # which field stopped it is the whole difference between this and a NoMethodError
      unless field_expr.respond_to?(:value)
        raise Z3::Exception, "Can't convert #{sort} into a Hash, field #{field.inspect} is #{field_expr.sort}, which has no #value"
      end
      field_expr.value
    end

    class << self
      # One subclass per tuple sort, holding that sort's field readers - the way
      # Struct.new builds a class rather than defining methods on every instance.
      #
      # A field named after something Expr already answers to (`sort`, `value`,
      # `to_s`) doesn't get one: taking those over would break the expression itself,
      # and `t[:sort]` reads the field regardless.
      def class_for(sort)
        Class.new(self) do
          sort.fields.each_key do |field|
            next if TupleExpr.method_defined?(field) or TupleExpr.private_method_defined?(field)
            define_method(field) { self[field] }
          end
          # The class is anonymous, and Ruby names it `#<Class:0x000...>` in every
          # NoMethodError about a field that doesn't exist - which is the one message
          # these classes are most likely to turn up in
          define_singleton_method(:name) { "Z3::TupleExpr(#{sort.name})" }
          define_singleton_method(:inspect) { name }
        end
      end
    end

    public_class_method :new
  end
end
