describe "Zebra Puzzle" do
  it do
    expect("zebra_puzzle").to have_output <<EOF
House 0: yellow Norwegian water Kools fox
House 1: blue Ukrainian tea Chesterfields horse
House 2: red Englishman milk Old Gold snails
House 3: ivory Spaniard orange juice Lucky Strike dog
House 4: green Japanese coffee Parliaments zebra
EOF
  end
end
