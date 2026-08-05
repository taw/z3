module Z3
  class FiniteDomainExpr < Expr
    # The Ruby Integer behind a finite domain value. The sort's values are 0 to
    # `size - 1` and Z3 gives them no names of their own, so unlike an EnumSort - the
    # other sort with a fixed set of values - there's nothing they could be but numbers.
    def value
      obj = ast_kind == :numeral ? self : simplify
      raise Z3::Exception, "Can't convert expression #{self} into Integer" unless obj.ast_kind == :numeral
      LowLevel.get_numeral_string(obj).to_i
    end

    public_class_method :new
  end
end
