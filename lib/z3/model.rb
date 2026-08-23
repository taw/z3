module Z3
  class Model
    include Enumerable
    include ReferenceCounted

    attr_reader :_model
    def initialize(_model)
      @_model = _model
      # Without this the solver reclaims the model as soon as it produces another one
      inc_ref! :model, _model
    end

    def num_consts
      LowLevel.model_get_num_consts(self)
    end

    def consts
      (0...num_consts).map do |i|
        FuncDecl.new(LowLevel.model_get_const_decl(self, i))
      end
    end

    def num_sorts
      LowLevel.model_get_num_sorts(self)
    end

    # The uninterpreted sorts the model had to invent elements for
    def sorts
      (0...num_sorts).map do |i|
        Sort.from_pointer(LowLevel.model_get_sort(self, i))
      end
    end

    # Every element the model gave an uninterpreted sort. Z3 only ever needs finitely
    # many, so this is the whole sort as far as this model is concerned.
    def sort_universe(sort)
      raise Z3::Exception, "Sort expected, got #{AST.describe(sort)}" unless sort.is_a?(Sort)
      LowLevel.unpack_ast_vector(LowLevel.model_get_sort_universe(self, sort))
    end

    def num_funcs
      funcs.size
    end

    # Recursive definitions are left out. Z3 puts every one made in the context into
    # every model, of every solver, whether or not the query so much as mentioned it -
    # `define-fun-rec` is context-global the way it is in an SMT-LIB script. It isn't
    # something this model decided, it's the definition handed straight back, and its
    # `else` branch is a body over de Bruijn variables which no Expr can hold, so
    # #func_interp on one raises rather than returning anything usable.
    def funcs
      (0...LowLevel.model_get_num_funcs(self)).map { |i|
        FuncDecl.new(LowLevel.model_get_func_decl(self, i))
      }.reject(&:recursive?)
    end

    # What the model decided a function does, as a Hash from argument lists to values
    # with Ruby's Hash default standing in for Z3's `else` branch - so `interp[[9]]`
    # answers for arguments the model never had to pin down.
    def func_interp(func_decl)
      raise Z3::Exception, "FuncDecl expected, got #{AST.describe(func_decl)}" unless func_decl.is_a?(FuncDecl)
      _func_interp = LowLevel.model_get_func_interp(self, func_decl)
      raise Z3::Exception, "Model has no interpretation for #{func_decl}" if _func_interp.null?
      LowLevel.unpack_func_interp(_func_interp)
    end

    def model_eval(ast, model_completion=false)
      Expr.new_from_pointer(LowLevel.model_eval(self, ast, model_completion))
    end

    def [](ast)
      model_eval(ast)
    end

    def to_s
      "Z3::Model<#{ map{|name, value| "#{name}=#{Printer.new.format_value(value)}"}.join(", ") }>"
    end

    def inspect
      to_s
    end

    # Constants come back as `variable, value` pairs, functions as `func_decl,
    # interpretation` - see #func_interp for what an interpretation looks like
    def each(&block)
      return to_enum(:each) unless block_given?
      each_const(&block)
      each_func(&block)
    end

    def each_const
      return to_enum(:each_const) unless block_given?
      consts.sort_by { |c| c.name.to_s }.each do |c|
        yield(
          c.range.var(c.name),
          Expr.new_from_pointer(LowLevel.model_get_const_interp(self, c))
        )
      end
    end

    def each_func
      return to_enum(:each_func) unless block_given?
      funcs.sort_by { |f| f.name.to_s }.each do |f|
        yield(f, func_interp(f))
      end
    end

    # Only constants are negated. Saying "some function differs somewhere" needs a
    # quantifier, so a model with functions in it can repeat under this.
    def !
      differences = []
      each_const { |var, _value| differences << (var != self[var]) }
      # A model with no consts constrains nothing, so there is nothing to differ in
      return Z3.False if differences.empty?
      Z3.Or(*differences)
    end
  end
end
