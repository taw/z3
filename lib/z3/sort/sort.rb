module Z3
  class Sort < AST
    def initialize(_ast)
      super(_ast)
      raise Z3::Exception, "Sorts must have AST kind sort" unless ast_kind == :sort
    end

    include Comparable
    def ==(other)
      other.is_a?(Sort) and @_ast == other._ast
    end

    def >(other)
      raise ArgumentError unless other.is_a?(Sort)
      false
    end

    # Reimplementing Comparable
    # Check if it can handle partial orders OK
    def <(other)
      raise ArgumentError unless other.is_a?(Sort)
      other > self
    end

    def >=(other)
      raise ArgumentError unless other.is_a?(Sort)
      self == other or self > other
    end

    def <=(other)
      raise ArgumentError unless other.is_a?(Sort)
      other >= self
    end

    def <=>(other)
      raise ArgumentError unless other.is_a?(Sort)
      return 0 if self == other
      return 1 if self > other
      return -1 if other > self
      nil
    end

    def to_s
      LowLevel.ast_to_string(self)
    end

    def eql?(other)
      self == other
    end

    # Z3 hash-conses sorts, and Set(X) is really Array(X, Bool), so two sorts can be
    # == while their Ruby classes differ. hash has to follow the pointer like eql? does,
    # or sorts which are eql? would end up in different Hash buckets.
    def hash
      _ast.address
    end

    def inspect
      "#{self}Sort"
    end

    def var(name)
      if name.is_a?(Enumerable)
        name.map{|v| var(v)}
      else
        new(
          LowLevel.mk_const(
            LowLevel.mk_string_symbol(name),
            self,
          )
        )
      end
    end

    # A variable Z3 names for you, by appending a number to `prefix` - for the ones
    # you need but don't want to have to name, and which mustn't collide with
    # anything the caller has named.
    #
    # `Z3.Const` is a different thing entirely: that's a literal built from a Ruby
    # value, where this is a variable, which is what Z3 calls a const.
    #
    # The number comes from a counter shared by the whole context, and by
    # FuncDecl.declare_fresh too, so don't count on getting any particular one.
    def fresh_var(prefix)
      new(LowLevel.mk_fresh_const(prefix.to_s, self))
    end

    # We pretend to be a class, sort of
    def new(_ast)
      expr_class.new(_ast, self)
    end

    def value_class
      raise "SubclassResponsibility"
    end

    def from_value(v)
      return v if v.sort == self
      raise cant_convert(v)
    end

    def cast(a)
      if a.is_a?(Expr)
        if  a.sort == self
          a
        else
          from_value(a)
        end
      else
        from_const(a)
      end
    end

    # Every failed conversion into a sort goes through here, so they're all worded the
    # way Ruby words its own: `Integer(nil)` says "can't convert nil into Integer"
    def cant_convert(value)
      Z3::Exception.new("Can't convert #{AST.describe(value)} into #{self}")
    end

    # FiniteSetSort added in 5.0
    def self.finite_sets?
      return @finite_sets unless @finite_sets.nil?
      @finite_sets = Z3.version_at_least?(5, 0)
    end

    def self.from_pointer(_sort)
      # FiniteSetSort didn't get its dedicated Z3_sort_kind value
      # so we need to call a special function to check for it.
      # But that function was only added in 5.0. Pre-5.0 we can't have finite sets anyway.
      if finite_sets? and VeryLowLevel.Z3_is_finite_set_sort(LowLevel._ctx_pointer, _sort)
        return FiniteSetSort.new(
          from_pointer(VeryLowLevel.Z3_get_finite_set_sort_basis(LowLevel._ctx_pointer, _sort))
        )
      end

      kind = VeryLowLevel.Z3_get_sort_kind(LowLevel._ctx_pointer, _sort)
      case kind
      when 0
        UninterpretedSort.new(name_from_pointer(_sort))
      when 1
        BoolSort.new
      when 2
        IntSort.new
      when 3
        RealSort.new
      when 4
        n = VeryLowLevel.Z3_get_bv_sort_size(LowLevel._ctx_pointer, _sort)
        BitvecSort.new(n)
      when 5
        domain = from_pointer(VeryLowLevel.Z3_get_array_sort_domain(LowLevel._ctx_pointer, _sort))
        range = from_pointer(VeryLowLevel.Z3_get_array_sort_range(LowLevel._ctx_pointer, _sort))
        if range == BoolSort.new
          SetSort.new(domain)
        else
          ArraySort.new(domain, range)
        end
      when 6
        datatype_from_pointer(_sort)
      when 8
        FiniteDomainSort.new(
          name_from_pointer(_sort),
          LowLevel.get_finite_domain_sort_size(_sort),
        )
      when 9
        e = VeryLowLevel.Z3_fpa_get_ebits(LowLevel._ctx_pointer, _sort)
        s = VeryLowLevel.Z3_fpa_get_sbits(LowLevel._ctx_pointer, _sort)
        FloatSort.new(e, s)
      when 10
        RoundingModeSort.new
      when 11
        # SeqSort.new turns Seq(Char) back into a StringSort, just like Set(X) is really Array(X, Bool)
        SeqSort.new(from_pointer(VeryLowLevel.Z3_get_seq_sort_basis(LowLevel._ctx_pointer, _sort)))
      when 12
        seq_sort = from_pointer(VeryLowLevel.Z3_get_re_sort_basis(LowLevel._ctx_pointer, _sort))
        ReSort.new(seq_sort)
      when 13
        CharSort.new
      when 14
        TypeVariableSort.new(name_from_pointer(_sort))
      else
        raise Z3::Exception, "Unknown sort kind #{kind}"
      end
    end

    # Z3 has one sort kind for every datatype, and this gem has three classes over it,
    # told apart by shape: an enumeration, whose constructors all take no arguments; a
    # tuple, which has exactly one constructor and it takes the fields; and a general
    # datatype for everything else. The shapes are what `DatatypeSort.new` checks
    # before declaring anything, so that declaring a sort and getting it back out of a
    # model always land on the same class.
    #
    # All three are rebuilt rather than redeclared - see EnumSort.from_pointer.
    def self.datatype_from_pointer(_sort)
      num_constructors = VeryLowLevel.Z3_get_datatype_sort_num_constructors(LowLevel._ctx_pointer, _sort)
      arities = num_constructors.times.map do |i|
        FuncDecl.new(VeryLowLevel.Z3_get_datatype_sort_constructor(LowLevel._ctx_pointer, _sort, i)).arity
      end
      return EnumSort.from_pointer(_sort) if arities.all?(&:zero?)
      return TupleSort.from_pointer(_sort) if num_constructors == 1
      DatatypeSort.from_pointer(_sort)
    end

    # Sorts with a name (uninterpreted, finite domain, enum, tuple, type variable) need
    # it to be rebuilt. Takes a raw pointer, as from_pointer needs it before there's a Sort.
    def self.name_from_pointer(_sort)
      LowLevel.symbol_value(VeryLowLevel.Z3_get_sort_name(LowLevel._ctx_pointer, _sort))
    end
  end
end
