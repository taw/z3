describe "Bridges" do
  let(:executable) { "#{__dir__}/../../examples/bridges_solver" }
  it "can solve bridges puzzle" do
    expect(IO.popen(executable).read.gsub(/ *$/, "")).to eq <<EOF

 3========6========4
 |        ‖        ‖
 |        ‖        ‖
 |  1     ‖        ‖
 |  |     ‖        ‖
 |  |     ‖        ‖
 |  |     4=====4  ‖
 |  |           ‖  ‖
 |  |           ‖  ‖
 |  |           ‖  ‖
 |  |           ‖  ‖
 |  |           ‖  ‖
 |  |  1-----3  ‖  ‖
 |  |        ‖  ‖  ‖
 |  |        ‖  ‖  ‖
 1  |        ‖  2  ‖
    |        ‖     ‖
    |        ‖     ‖
    3========5-----3

EOF
  end
end
