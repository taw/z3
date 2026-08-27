module Z3
  class Model
    include Enumerable
    include ReferenceCounted

    attr_reader :_model

    # Either a model Z3 produced - `Solver#model` and `Optimize#model` pass their
    # pointer in here - or one built from what it should say, which is the same shape
    # #each yields back:
    #
    #   Model.new(x => 3, y => 4)
    #   Model.new(f => {[1] => 10, [2] => 20, default: 0})
    #
    # Keys are variables or FuncDecls, values are anything their sort can cast, and a
    # function's entries are keyed by argument list - `[1]` even for a unary function.
    # `default:` is the `else` branch, the answer for every argument list without an
    # entry, and Z3 insists a function have one. Ruby's own Hash default says the same
    # thing, which is where #func_interp puts it, so a model read out goes back in:
    # `Model.new(model.to_h)` round trips.
    #
    # A model built here is a model like any other - #model_eval evaluates any
    # expression against it, without a solver anywhere in sight, and Goal#convert_model
    # takes one - but it is only what it was told: nothing checks it against any
    # assertions, and it can perfectly well say something false.
    #
    # Two things it can't be told. The elements Z3 invents for an uninterpreted sort
    # have no writer in the C API at all, so #sorts on a model built here is empty
    # however many of them its values mention. And a recursive definition belongs to
    # the context rather than to any model, so one is refused - see #funcs.
    def initialize(interps = {})
      @_model =
        case interps
        when Hash
          LowLevel.mk_model
        when FFI::Pointer
          interps
        else
          # FFI would take anything numeric here as an address and segfault on it
          raise Z3::Exception, "A model is built from a Hash of interpretations, got #{AST.describe(interps)}"
        end
      # Without this the solver reclaims the model as soon as it produces another one
      inc_ref! :model, @_model
      add_interps(interps) if interps.is_a?(Hash)
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

    # Whether the model says anything at all about this variable or function. It's the
    # question #model_eval can't answer: without `model_completion` an unassigned
    # variable evaluates to itself, and with it Z3 invents a value rather than telling
    # you it had to.
    def has_interp?(key)
      LowLevel.model_has_interp(self, interp_decl(key))
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

    private

    def add_interps(interps)
      interps.each do |key, value|
        decl = interp_decl(key)
        if decl.arity == 0
          LowLevel.add_const_interp(self, decl, decl.range.cast(value))
        else
          LowLevel.pack_func_interp(self, decl, func_interp_for(decl, value))
        end
      end
    end

    # A variable is an Expr - that's how #each_const yields one - and a function is a
    # FuncDecl, which is how #each_func does. Either way what Z3 wants is the decl.
    def interp_decl(key)
      decl =
        case key
        when FuncDecl
          key
        when Expr
          unless key.ast_kind == :app and key.func_decl.arity == 0
            raise Z3::Exception, "A model says what variables and functions are, and #{key.inspect} is neither"
          end
          key.func_decl
        else
          raise Z3::Exception, "A model says what variables and functions are, and #{AST.describe(key)} is neither"
        end
      # Z3 takes an interpretation for one of these and then answers from the definition
      # anyway, the same way #funcs leaves them out of a model it read - see #funcs
      if decl.recursive?
        raise Z3::Exception, "#{decl.name} is defined in the context, so a model can't say what it is"
      end
      decl
    end

    # Same Hash #func_interp gives back, with everything cast into the declared sorts
    def func_interp_for(decl, interp)
      unless interp.is_a?(Hash)
        raise Z3::Exception, "#{decl.name} is a function, so it needs a Hash of argument lists to values, got #{AST.describe(interp)}"
      end
      entries = interp.reject { |args, _| args == :default }
      else_value = interp.key?(:default) ? interp[:default] : interp.default
      if else_value.nil?
        raise Z3::Exception, "#{decl.name} needs a `default:` - Z3 wants an answer for the argument lists with no entry"
      end
      result = {}
      entries.each do |args, value|
        unless args.is_a?(Array) and args.size == decl.arity
          raise Z3::Exception, "#{decl.name} takes #{decl.arity} argument#{"s" unless decl.arity == 1}, so #{args.inspect} is not an argument list for it"
        end
        result[args.each_with_index.map { |arg, i| decl.domain(i).cast(arg) }] = decl.range.cast(value)
      end
      result.default = decl.range.cast(else_value)
      result
    end
  end
end
