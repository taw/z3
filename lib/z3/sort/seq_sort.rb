module Z3
  class SeqSort < Sort
    # Z3 has no String sort of its own, String is just Seq(Char) - so Seq(Char) has to
    # come back as a StringSort, or we'd have two Ruby classes for one Z3 sort
    def self.new(element_sort)
      return StringSort.new if element_sort == CharSort.new
      super
    end

    attr_reader :element_sort
    def initialize(element_sort)
      @element_sort = element_sort
      super LowLevel.mk_seq_sort(element_sort)
    end

    def expr_class
      SeqExpr
    end

    # Z3 has no sequence literals, a sequence value is a concatenation of one element
    # sequences - and it rejects a concatenation of fewer than two of them
    def from_const(val)
      raise Z3::Exception, "Cannot convert #{val.class} to #{self.class}" unless val.is_a?(Array)
      units = val.map { |v| new(LowLevel.mk_seq_unit(element_sort.cast(v))) }
      case units.size
      when 0
        new(LowLevel.mk_seq_empty(self))
      when 1
        units[0]
      else
        new(LowLevel.mk_seq_concat(units))
      end
    end

    def to_s
      "Seq(#{element_sort})"
    end

    def inspect
      "SeqSort(#{element_sort})"
    end

    public_class_method :new
  end
end
