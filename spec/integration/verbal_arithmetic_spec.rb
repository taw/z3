describe "Bridges" do
  let(:executable) { "#{__dir__}/../../examples/verbal_arithmetic" }
  it "can solve verbal arithmetic puzzles" do
    expect(IO.popen(executable).read).to eq <<EOF
[["S", 9], ["E", 5], ["N", 6], ["D", 7]]
[["M", 1], ["O", 0], ["R", 8], ["E", 5]]
[["M", 1], ["O", 0], ["N", 6], ["E", 5], ["Y", 2]]
EOF
  end
end
