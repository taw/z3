describe "LightUp" do
  let(:executable) { "#{__dir__}/../../examples/light_up_solver" }
  it "can solve light up puzzle" do
    expect(IO.popen(executable).read.gsub(/ *$/, "")).to eq <<EOF
  * 0
*
x 2*x
  *3  *
* x*x*3
      *
 *1 *
EOF
  end
end
