describe "Geometry Problem" do
  let(:executable) { "#{__dir__}/../../examples/geometry_problem" }
  it "can solve geometry problem" do
    expect(IO.popen(executable).read).to eq <<EOF
* a.x = 0.0
* a.y = (root-obj (+ (^ x 2) (- 300)) 1)
* b.x = 0.0
* b.y = 0.0
* c.x = 10.0
* c.y = 0.0
* d.x = 10.0
* d.y = (root-obj (+ (^ x 2) (- 300)) 1)
* |a-c| = (- 20.0)
* |b-d| = 20.0
EOF
  end
end
