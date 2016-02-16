describe "MiniSudoku" do
  let(:executable) { "#{__dir__}/../../examples/minisudoku_solver" }
  it "can solve minisudoku" do
    expect(IO.popen(executable).read).to eq <<EOF
2 1 5 4 3 6
3 6 4 1 2 5
1 3 6 5 4 2
4 5 2 3 6 1
5 2 3 6 1 4
6 4 1 2 5 3
EOF
  end
end