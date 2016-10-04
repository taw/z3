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

    public_class_method :new
  end
end
