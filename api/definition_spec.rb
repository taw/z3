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
      expect(ffi).to eq("attach_function :Z3_mk_ge, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer")
      expect(api_def).to eq("mk_ge(a,b)")
      expect(api_body).to eq(
        "Z3::VeryLowLevel.Z3_mk_ge(_ctx_pointer, a._ast, b._ast)"
      )
    end
  end

  describe "mk_numeral" do
    let(:defstr) { "def_API('Z3_mk_numeral', AST, (_in(CONTEXT), _in(STRING), _in(SORT)))" }
    it do
      expect(supported).to eq(true)
      expect(ffi).to eq("attach_function :Z3_mk_numeral, [ctx_pointer, :string, sort_pointer], ast_pointer")
      expect(api_def).to eq("mk_numeral(str, sort)")
      expect(api_body).to eq(
        "Z3::VeryLowLevel.Z3_mk_numeral(_ctx_pointer, str, sort._sort)"
      )
    end
  end

  describe "mk_bv_sort" do
    let(:defstr) { "def_API('Z3_mk_bv_sort', SORT, (_in(CONTEXT), _in(UINT)))" }
    it do
      expect(supported).to eq(true)
      expect(api_def).to eq("mk_numeral(n)")
    end
  end
end
