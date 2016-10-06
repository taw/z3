module Z3
  class FloatSort < Sort
    def initialize(e, s=nil)
      if s.nil?
        case e
        when 16
          super LowLevel.mk_fpa_sort_16
        when 32
          super LowLevel.mk_fpa_sort_32
        when 64
          super LowLevel.mk_fpa_sort_64
        when 128
          super LowLevel.mk_fpa_sort_128
        when :half
          super LowLevel.mk_fpa_sort_half
        when :single
          super LowLevel.mk_fpa_sort_single
        when :double
          super LowLevel.mk_fpa_sort_double
        when :quadruple
          super LowLevel.mk_fpa_sort_quadruple
        else
          raise "Unknown float type #{e}, use FloatSort.new(exponent_bits, significant_bits)"
        end
      else
        super LowLevel.mk_fpa_sort(e, s)
      end
    end

    def expr_class
      FloatExpr
    end

    def from_const(val)
      if val.is_a?(Float)
        new LowLevel.mk_fpa_numeral_double(val, self)
      elsif val.is_a?(Integer)
        val_f = val.to_f
        # FIXME, there are other constructors
        raise Z3::Exception, "Out of range" unless val_f == val
        new LowLevel.mk_fpa_numeral_double(val_f, self)
      else
        raise Z3::Exception, "Cannot convert #{val.class} to #{self.class}"
      end
    end

    def >(other)
      raise ArgumentError unless other.is_a?(Sort)
      return true if other.is_a?(IntSort) # This is nasty...
      return true if other.is_a?(RealSort) # This is nasty...
      false
    end

    def ebits
      LowLevel.fpa_get_ebits(self)
    end

    def sbits
      LowLevel.fpa_get_sbits(self)
    end

    def to_s
      "Float(#{ebits}, #{sbits})"
    end

    def inspect
      "FloatSort(#{ebits}, #{sbits})"
    end

    def nan
      new LowLevel.mk_fpa_nan(self)
    end

    def positive_infinity
      new LowLevel.mk_fpa_inf(self, false)
    end

    def negative_infinity
      new LowLevel.mk_fpa_inf(self, true)
    end

    def positive_zero
      new LowLevel.mk_fpa_zero(self, false)
    end

    def negative_zero
      new LowLevel.mk_fpa_zero(self, true)
    end

    public_class_method :new
  end
end
