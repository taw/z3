require_relative "definition"

describe Definition do
  let(:definition) { Definition.new(defstr) }
  let(:supported) { definition.supported? }
  let(:ffi) { definition.ffi }
  let(:api_def) { definition.api_def }
  let(:api_body) { definition.api_body }

  describe "mk_ge" do
    let(:defstr) { "def_API('Z3_mk_ge', AST, (_in(CONTEXT), _in(AST), _in(AST)))" }
    it do
      expect(supported).to eq(true)
      expect(ffi).to eq("    attach_function :Z3_mk_ge, [:ctx_pointer, :ast_pointer, :ast_pointer], :ast_pointer")
      expect(api_def).to eq("mk_ge(ast1, ast2)")
      expect(api_body).to eq(
        "VeryLowLevel.Z3_mk_ge(_ctx_pointer, ast1._ast, ast2._ast)"
      )
    end
  end

  describe "mk_numeral" do
    let(:defstr) { "def_API('Z3_mk_numeral', AST, (_in(CONTEXT), _in(STRING), _in(SORT)))" }
    it do
      expect(supported).to eq(true)
      expect(ffi).to eq("    attach_function :Z3_mk_numeral, [:ctx_pointer, :string, :sort_pointer], :ast_pointer")
      expect(api_def).to eq("mk_numeral(str, sort)")
      expect(api_body).to eq(
        "VeryLowLevel.Z3_mk_numeral(_ctx_pointer, str, sort._ast)"
      )
    end
  end

  describe "mk_bv_sort" do
    let(:defstr) { "def_API('Z3_mk_bv_sort', SORT, (_in(CONTEXT), _in(UINT)))" }
    it do
      expect(supported).to eq(true)
      expect(ffi).to eq("    attach_function :Z3_mk_bv_sort, [:ctx_pointer, :uint], :sort_pointer")
      expect(api_def).to eq("mk_bv_sort(num)")
      expect(api_body).to eq(
        "VeryLowLevel.Z3_mk_bv_sort(_ctx_pointer, num)"
      )
    end
  end

  describe "mk_parser_context" do
    let(:defstr) { "def_API('Z3_mk_parser_context', PARSER_CONTEXT, (_in(CONTEXT),))" }
    it do
      expect(supported).to eq(true)
      expect(ffi).to eq("    attach_function :Z3_mk_parser_context, [:ctx_pointer], :parser_context_pointer")
      expect(api_def).to eq("mk_parser_context")
      expect(api_body).to eq(
        "VeryLowLevel.Z3_mk_parser_context(_ctx_pointer)"
      )
    end
  end

  describe "parser_context_add_decl" do
    let(:defstr) { "def_API('Z3_parser_context_add_decl', VOID, (_in(CONTEXT), _in(PARSER_CONTEXT), _in(FUNC_DECL)))" }
    it do
      expect(supported).to eq(true)
      expect(ffi).to eq("    attach_function :Z3_parser_context_add_decl, [:ctx_pointer, :parser_context_pointer, :func_decl_pointer], :void")
      expect(api_def).to eq("parser_context_add_decl(parser_context, func_decl)")
      expect(api_body).to eq(
        "VeryLowLevel.Z3_parser_context_add_decl(_ctx_pointer, parser_context._parser_context, func_decl._ast)"
      )
    end
  end

  describe "solver_add_simplifier" do
    let(:defstr) { "def_API('Z3_solver_add_simplifier', SOLVER, (_in(CONTEXT), _in(SOLVER), _in(SIMPLIFIER)))" }
    it do
      expect(supported).to eq(true)
      expect(ffi).to eq("    attach_function :Z3_solver_add_simplifier, [:ctx_pointer, :solver_pointer, :simplifier_pointer], :solver_pointer")
      expect(api_def).to eq("solver_add_simplifier(solver, simplifier)")
      expect(api_body).to eq(
        "VeryLowLevel.Z3_solver_add_simplifier(_ctx_pointer, solver._solver, simplifier._simplifier)"
      )
    end
  end

  # ERROR_CODE and PRINT_MODE are C enums, so they cross FFI as plain ints
  describe "get_error_msg" do
    let(:defstr) { "def_API('Z3_get_error_msg', STRING, (_in(CONTEXT), _in(ERROR_CODE)))" }
    it do
      expect(supported).to eq(true)
      expect(ffi).to eq("    attach_function :Z3_get_error_msg, [:ctx_pointer, :int], :string")
      expect(api_def).to eq("get_error_msg(error_code)")
      expect(api_body).to eq(
        "VeryLowLevel.Z3_get_error_msg(_ctx_pointer, error_code)"
      )
    end
  end

  describe "get_arity" do
    let(:defstr) { "def_API('Z3_get_arity', UINT, (_in(CONTEXT), _in(FUNC_DECL)))" }
    it do
      expect(supported).to eq(true)
      expect(ffi).to eq("    attach_function :Z3_get_arity, [:ctx_pointer, :func_decl_pointer], :uint")
      expect(api_def).to eq("get_arity(func_decl)")
      expect(api_body).to eq(
        "VeryLowLevel.Z3_get_arity(_ctx_pointer, func_decl._ast)"
      )
    end
  end
end
