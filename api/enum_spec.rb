require_relative "enum"

describe Enum do
  let(:enum) { Enum.new(enum_str) }

  describe "implicit values, counting from 0" do
    let(:enum_str) { <<~C }
      typedef enum
      {
          Z3_INT_SYMBOL,
          Z3_STRING_SYMBOL
      } Z3_symbol_kind;
    C

    it do
      expect(enum.name).to eq("Z3_symbol_kind")
      expect(enum.ruby_name).to eq("SYMBOL_KIND")
      expect(enum.entries).to eq(0 => "Z3_INT_SYMBOL", 1 => "Z3_STRING_SYMBOL")
    end
  end

  describe "an explicit negative value, still incrementing from there" do
    let(:enum_str) { <<~C }
      typedef enum
      {
          Z3_L_FALSE = -1,
          Z3_L_UNDEF,
          Z3_L_TRUE
      } Z3_lbool;
    C

    it do
      expect(enum.entries).to eq(-1 => "Z3_L_FALSE", 0 => "Z3_L_UNDEF", 1 => "Z3_L_TRUE")
    end
  end

  describe "explicit hex values resetting the count between families, comments and blank lines ignored" do
    let(:enum_str) { <<~C }
      typedef enum {
          // Basic
          Z3_OP_TRUE = 0x100,
          Z3_OP_FALSE,

          // Arithmetic
          Z3_OP_ANUM = 0x200,
          Z3_OP_LE
      } Z3_decl_kind;
    C

    it do
      expect(enum.entries).to eq(
        256 => "Z3_OP_TRUE",
        257 => "Z3_OP_FALSE",
        512 => "Z3_OP_ANUM",
        513 => "Z3_OP_LE",
      )
    end
  end

  describe "an explicit value with no space around `=`" do
    let(:enum_str) { <<~C }
      typedef enum {
          Z3_OP_DT_CONSTRUCTOR=0x800,
          Z3_OP_DT_RECOGNISER
      } Z3_decl_kind;
    C

    it do
      expect(enum.entries).to eq(2048 => "Z3_OP_DT_CONSTRUCTOR", 2049 => "Z3_OP_DT_RECOGNISER")
    end
  end

  it "#ruby renders a frozen Ruby Hash literal keyed by value" do
    enum = Enum.new(<<~C)
      typedef enum
      {
          Z3_INT_SYMBOL,
          Z3_STRING_SYMBOL
      } Z3_symbol_kind;
    C
    expect(enum.ruby).to eq(<<~RUBY)
      \x20\x20\x20\x20SYMBOL_KIND = {
      \x20\x20\x20\x20\x20\x200 => "Z3_INT_SYMBOL",
      \x20\x20\x20\x20\x20\x201 => "Z3_STRING_SYMBOL",
      \x20\x20\x20\x20}.freeze
    RUBY
  end

  it "#<=> sorts by name, so output is deterministic regardless of header order" do
    a = Enum.new("typedef enum { Z3_A } Z3_a;")
    b = Enum.new("typedef enum { Z3_B } Z3_b;")
    expect([b, a].sort).to eq([a, b])
  end

  it "raises on an entry it can't parse" do
    expect { Enum.new("typedef enum { Z3_OP_WEIRD(1) } Z3_decl_kind;") }
      .to raise_error(/Can't parse enum entry/)
  end
end
