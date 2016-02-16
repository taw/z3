describe "Basic Logic" do
  let(:executable) { "#{__dir__}/../../examples/basic_logic" }
  it "can solve verbal arithmetic puzzles" do
    expect(IO.popen(executable).read).to eq <<EOF
Checking if true == true
Proven
Checking if true == false
Counterexample exists
Proving ~(a & b) == (~a | ~b)
Proven
Proving ~(a | b) == (~a & ~b)
Proven
EOF
  end
end
