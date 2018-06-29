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

    def hash
      self.class.hash
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

    # We pretend to be a class, sort of
    def new(_ast)
      expr_class.new(_ast, self)
    end

    def value_class
      raise "SubclassResponsibility"
    end

    def from_value(v)
      return v if v.sort == self
      raise Z3::Exception, "Can't convert #{v.sort} into #{self}"
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

    def self.from_pointer(_sort)
      kind = VeryLowLevel.Z3_get_sort_kind(LowLevel._ctx_pointer, _sort)
      case kind
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
      when 9
        e = VeryLowLevel.Z3_fpa_get_ebits(LowLevel._ctx_pointer, _sort)
        s = VeryLowLevel.Z3_fpa_get_sbits(LowLevel._ctx_pointer, _sort)
        FloatSort.new(e, s)
      when 10
        RoundingModeSort.new
      else
        raise "Unknown sort kind #{kind}"
      end
    end
  end
end
