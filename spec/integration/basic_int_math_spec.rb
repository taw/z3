describe "Basic Int Math" do
  let(:executable) { "#{__dir__}/../../examples/basic_int_math" }
  it "can solve basic integer math problems" do
    expect(IO.popen(executable).read).to eq <<EOF
Checking if (a+b)(a-b)==a*a-b*b
Proven
Checking if a+b >= a
Counterexample exists
* b = (- 1)
Checking if a+b >= a if a,b >= 0
Proven
EOF
  end
end
