module Z3
  class FuncDecl < AST
    def initialize(_ast)
      super(_ast)
      raise Z3::Exception, "FuncDecls must have AST kind func decl" unless ast_kind == :func_decl
    end

    def name
      LowLevel.get_symbol_string(LowLevel.get_decl_name(self))
    end

    def arity
      LowLevel.get_arity(self)
    end

    def domain(i)
      a = arity
      raise Z3::Exception, "Trying to access domain #{i} but function arity is #{a}" if i < 0 or i >= a
      Sort.from_pointer(LowLevel::get_domain(self, i))
    end

    def range
      Sort.from_pointer(LowLevel::get_range(self))
    end

    # Decl parameters are the `_`-part of an indexed decl like
    # `(_ map or)`, `(_ extract 7 0)`, `(_ zero_extend 8)`.
    # They have nothing to do with the domain, so they're not counted by #arity.
    PARAMETER_KINDS = {
      0 => :int,
      1 => :double,
      2 => :rational,
      3 => :symbol,
      4 => :sort,
      5 => :ast,
      6 => :func_decl,
      7 => :internal,
      8 => :zstring,
    }

    def num_parameters
      LowLevel.get_decl_num_parameters(self)
    end

    def parameter_kind(i)
      raise Z3::Exception, "Trying to access parameter #{i} but decl has #{num_parameters} parameters" if i < 0 or i >= num_parameters
      k = LowLevel.get_decl_parameter_kind(self, i)
      PARAMETER_KINDS.fetch(k) { raise Z3::Exception, "Unknown decl parameter kind #{k}" }
    end

    # What the decl is indexed *by*, as an ordinary Ruby object. The decl name is the
    # same for every extract - `(_ extract 7 0)` and `(_ extract 3 2)` are both called
    # "extract" - so the parameters are the only place the 7 and the 0 exist.
    #
    # Two of the nine kinds can't be read back: `:zstring` has no accessor in the C API
    # at all (use `Expr#value` on the literal instead), and `:internal` is opaque by
    # definition.
    def parameter(i)
      case (kind = parameter_kind(i))
      when :int
        LowLevel.get_decl_int_parameter(self, i)
      when :double
        LowLevel.get_decl_double_parameter(self, i)
      when :rational
        # Z3 hands this one over as a string, in Ruby's own `3/4` spelling
        Rational(LowLevel.get_decl_rational_parameter(self, i))
      when :symbol
        LowLevel.symbol_value(LowLevel.get_decl_symbol_parameter(self, i))
      when :sort
        Sort.from_pointer(LowLevel.get_decl_sort_parameter(self, i))
      when :ast
        Expr.new_from_pointer(LowLevel.get_decl_ast_parameter(self, i))
      when :func_decl
        func_decl_parameter(i)
      when :zstring
        raise Z3::Exception, "Parameter #{i} is a string, and Z3 offers no way to read one back - use Expr#value on the literal instead"
      else
        raise Z3::Exception, "Parameter #{i} is #{kind}, which Z3 keeps to itself"
      end
    end

    def func_decl_parameter(i)
      raise Z3::Exception, "Parameter #{i} is a #{parameter_kind(i)}, not a func decl" unless parameter_kind(i) == :func_decl
      FuncDecl.new(LowLevel.get_decl_func_decl_parameter(self, i))
    end

    # Applies the function. Arguments are cast to the declared domain and the result
    # has the declared range, so it composes like any other expression.
    def [](*args)
      unless args.size == arity
        raise Z3::Exception, "#{name} takes #{arity} argument#{"s" unless arity == 1}, got #{args.size}"
      end
      range.new(LowLevel.mk_app(self, args.each_with_index.map { |arg, i| domain(i).cast(arg) }))
    end

    def call(*args)
      self[*args]
    end

    # Z3 hash-conses declarations, so two decls of the same name and signature are
    # one and the same. AST already gives us #eql? and #hash on the pointer; without
    # this they'd disagree with ==, which would be an odd thing for a Hash key to do.
    # (Expr overrides == to build an expression instead - a FuncDecl is not a value,
    # so there's nothing to build.)
    def ==(other)
      eql?(other)
    end

    def to_s
      name
    end

    def inspect
      "Z3::FuncDecl<#{name}/#{arity}>"
    end

    class << self
      def declare(name, *sorts)
        domain, range = split_signature(sorts)
        new(LowLevel.mk_func_decl(LowLevel.mk_symbol(name), domain, range))
      end

      # Z3 appends a number to `prefix`, picking one no declaration is using yet.
      # It's only unused as of now though - nothing stops a later #declare from
      # claiming the same name and getting this very same func decl back.
      def declare_fresh(prefix, *sorts)
        domain, range = split_signature(sorts)
        new(LowLevel.mk_fresh_func_decl(prefix.to_s, domain, range))
      end

      private

      # Last sort is the range, the ones before it are the domain
      def split_signature(sorts)
        raise Z3::Exception, "Function needs at least a range sort" if sorts.empty?
        sorts.each do |sort|
          raise Z3::Exception, "Sort expected, got #{AST.describe(sort)}" unless sort.is_a?(Sort)
        end
        [sorts[0..-2], sorts[-1]]
      end
    end

    public_class_method :new
  end
end
