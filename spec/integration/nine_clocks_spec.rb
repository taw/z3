describe "Nine Clocks" do
  it do
    expect("nine_clocks").to have_output <<EOF
IN:
1 0 1
0 2 3
1 3 2
OUT:
1 0 0
0 0 0
0 0 0
IN:
0 2 0
2 3 2
3 3 3
OUT:
0 1 0
0 0 0
0 0 0
IN:
2 3 2
3 1 3
2 3 2
OUT:
0 0 0
0 1 0
0 0 0
EOF
  end
end
