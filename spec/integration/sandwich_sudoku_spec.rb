describe "Sandwich Sudoku" do
  it do
    expect("sandwich_sudoku").to have_output <<EOF
4 8 5 6 7 9 3 2 1
3 2 9 5 8 1 6 4 7
7 1 6 2 3 4 5 9 8
1 7 2 9 5 3 8 6 4
6 9 4 8 1 2 7 3 5
8 5 3 7 4 6 9 1 2
5 3 1 4 9 7 2 8 6
9 6 8 1 2 5 4 7 3
2 4 7 3 6 8 1 5 9
EOF
  end
end
