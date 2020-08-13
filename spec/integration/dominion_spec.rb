describe "Dominion" do
  it do
    expect("dominion").to have_output <<EOF
**AAAA*B
FF*AAA*B
FF*A**BB
F*E*GG**
F*E*G*DD
*G*GG*DD
*G*G*C**
GGGG*CCC
EOF
  end
end
