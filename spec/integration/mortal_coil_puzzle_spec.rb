# There are multiple solutions, so this test is nondeterministic
# This is what Z3 4.8.13 returns
describe "Mortal Coil Puzzle" do
  it do
    expect("mortal_coil_puzzle").to have_output <<EOF
  4   3   2 ###  20  19
  5 ###   1 ###  21  18
  6  25  24  23  22  17
  7  26  27  28 ###  16
  8 ###  30  29 ###  15
  9  10  11  12  13  14
EOF
  end
end
