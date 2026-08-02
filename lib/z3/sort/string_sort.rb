module Z3
  # Z3 internally represents String as Seq(Char), so StringSort == SeqSort.new(CharSort.new)
  class StringSort < Sort
    def initialize
      super LowLevel.mk_string_sort
    end

    def element_sort
      CharSort.new
    end

    def expr_class
      Expr
    end

    # A Z3 string is a sequence of code points, so a Ruby String converts character by
    # character, not byte by byte - which means it has to be valid in its own encoding
    def from_const(val)
      raise Z3::Exception, "Cannot convert #{val.class} to #{self.class}" unless val.is_a?(String)
      raise Z3::Exception, "String is not valid #{val.encoding}" unless val.valid_encoding?
      val.each_codepoint do |code_point|
        next if code_point <= CharSort::MAX_CODE_POINT
        raise Z3::Exception, "Character 0x#{code_point.to_s(16).upcase} is outside Z3's alphabet (0 to 0x#{CharSort::MAX_CODE_POINT.to_s(16).upcase})"
      end
      new(LowLevel.mk_string(val))
    end

    public_class_method :new
  end
end
