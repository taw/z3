# This puzzle is ambiguous
# This is solution from z3 4.8.3

describe "OneOfUs" do
  it do
    expect("oneofus").to have_output <<EOF
grey Triangle grey Circle grey Triangle
purple Square grey Triangle purple Triangle
grey Triangle grey Square grey Triangle

Click 0: 2,2 - grey Triangle
Click 1: 2,0 - grey Triangle
Click 2: 0,0 - grey Triangle
Click 3: 0,2 - grey Triangle
Click 4: 1,2 - grey Square
Click 5: 1,0 - grey Circle
Click 6: 1,1 - grey Triangle
Click 7: 2,1 - purple Triangle
Click 8: 0,1 - purple Square
EOF
  end
end
