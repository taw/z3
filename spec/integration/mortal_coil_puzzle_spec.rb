describe "Mortal Coil Puzzle" do
  it do
    expect("mortal_coil_puzzle").to have_output <<EOF
 22  21  20 ###  14  13
 23 ###  19 ###  15  12
 24   1  18  17  16  11
 25   2   3   4 ###  10
 26 ###  30   5 ###   9
 27  28  29   6   7   8
EOF
  end
end
