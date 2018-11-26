# This puzzle is ambiguous and different z3 versions return different result,
# so just checking that it doesn't crash

describe "OneOfUs" do
  let(:binary) { Pathname(__dir__) + "../../examples/oneofus" }

  it do
    output = `#{binary}`.chomp
    expect(output.lines.size).to eq(13)
  end
end
