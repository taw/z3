describe "Light Up" do
  let(:binary) { Pathname(__dir__) + "../../examples/light_up" }

  # Walls don't need to be lit, only white cells do
  it "solves boards where a wall has no line of sight to any lamp" do
    board = Pathname(__dir__) + "../../examples/light_up-2.txt"
    expect(`#{binary} #{board}`).to eq("0 \n *\n")
  end

  it do
    expect("light_up").to have_output <<EOF
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
