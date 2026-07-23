module Z3
  class FuncDecl < AST
    def initialize(_ast)
      super(_ast)
      raise Z3::Exception, "FuncDecls must have AST kind func decl" unless ast_kind == :func_decl
    end

    def name
      LowLevel.get_symbol_string(LowLevel.get_decl_name(self))
    end

    def arity
      LowLevel.get_arity(self)
    end

    def domain(i)
      a = arity
      raise Z3::Exception, "Trying to access domain #{i} but function arity is #{a}" if i < 0 or i >= a
      Sort.from_pointer(LowLevel::get_domain(self, i))
    end

    def range
      Sort.from_pointer(LowLevel::get_range(self))
    end

    # Decl parameters are the `_`-part of an indexed decl like
    # `(_ map or)`, `(_ extract 7 0)`, `(_ zero_extend 8)`.
    # They have nothing to do with the domain, so they're not counted by #arity.
    PARAMETER_KINDS = {
      0 => :int,
      1 => :double,
      2 => :rational,
      3 => :symbol,
      4 => :sort,
      5 => :ast,
      6 => :func_decl,
      7 => :internal,
      8 => :zstring,
    }

    def num_parameters
      LowLevel.get_decl_num_parameters(self)
    end

    def parameter_kind(i)
      raise Z3::Exception, "Trying to access parameter #{i} but decl has #{num_parameters} parameters" if i < 0 or i >= num_parameters
      k = LowLevel.get_decl_parameter_kind(self, i)
      PARAMETER_KINDS.fetch(k) { raise Z3::Exception, "Unknown decl parameter kind #{k}" }
    end

    def func_decl_parameter(i)
      raise Z3::Exception, "Parameter #{i} is a #{parameter_kind(i)}, not a func decl" unless parameter_kind(i) == :func_decl
      FuncDecl.new(LowLevel.get_decl_func_decl_parameter(self, i))
    end

    def to_s
      name
    end

    def inspect
      "Z3::FuncDecl<#{name}/#{arity}>"
    end

    public_class_method :new
  end
end
