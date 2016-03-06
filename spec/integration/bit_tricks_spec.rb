describe "Bit Tricks" do
  let(:executable) { "#{__dir__}/../../examples/bit_tricks" }
  it "can validate bit tricks" do
    expect(IO.popen(executable).read.gsub(/ *$/, "")).to eq <<EOF
Validating sign trick:
Proven
Validating sign trick:
Proven
Validating abs without branching, version 1
Proven
Validating abs without branching, version 2
Proven
Validating min without branching
Proven
Validating max without branching
Proven
Validating is power of two
Proven
EOF
  end
end
