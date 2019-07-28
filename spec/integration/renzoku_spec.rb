describe "Renzoku" do
  it do
    expect("renzoku").to have_output <<EOF
2 4 7 1 3 9.8 5.6
  . .   .       .
6.5 8.9 4 1.2.3 7
.               .
7 9 2 5.6 3.4 1 8

4 7.6 3.2 8 1 9 5
. .   .
5 8 1 4 9 2 7.6 3
            .
8 3.4 7 1 5.6 2 9
  .   .
1.2 9 6.5 7 3 8 4
  .       .
9 1 3 8.7.6.5.4 2
        .       .
3 6.5 2 8 4 9 7 1
EOF
  end
end
