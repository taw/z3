describe "Futoshiki" do
  it do
    expect("futoshiki").to have_output <<EOF
2 5 3 4 1 7 6<9 8

1 9 7 2 8 5 3<4<6
  _
7<8 2 5>3>1 4<6 9
^
8 1<5<9 7 6 2 3 4
            ^
4 7>6>1 9 2 5 8 3
^         ^     ^
6 4 1 8 2 3 9 5 7
  _   _ ^   _ _
9 3 4 6>5 8 7 1 2
_
5 2 9>3 6>4 8>7 1
              _
3 6 8>7>4 9 1<2 5
EOF
  end
end
