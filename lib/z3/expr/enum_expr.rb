module Z3
  class EnumExpr < Expr
    # The Ruby Symbol behind an enum literal. Two enums are free to use the same
    # value name, so this only says anything together with the expression's sort.
    def value
      i = value_index || simplify.value_index
      raise Z3::Exception, "Can't convert expression #{self} into Symbol" unless i
      sort.values[i]
    end

    protected

    # Which of the sort's values this is, or nil if it isn't one of them. A variable
    # is an app too, and nothing stops one being named after a value, so matching the
    # decl itself is the only way to tell the value `red` from a variable called `red`.
    def value_index
      return nil unless ast_kind == :app
      sort.constructors.index(func_decl)
    end

    public_class_method :new
  end
end
