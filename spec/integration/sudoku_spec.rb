describe "Sudoku" do
  it do
    expect("sudoku").to have_output <<EOF
8 6 3 5 7 9 2 4 1
9 2 5 3 1 4 8 7 6
4 7 1 8 2 6 9 5 3
7 1 4 6 8 3 5 2 9
6 8 9 7 5 2 3 1 4
3 5 2 4 9 1 6 8 7
1 3 6 2 4 5 7 9 8
2 4 8 9 3 7 1 6 5
5 9 7 1 6 8 4 3 2
EOF
  end
end
