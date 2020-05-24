describe "Miracle Sudoku" do
  it do
    expect("miracle_sudoku").to have_output <<EOF
4 8 3 7 2 6 1 5 9
7 2 6 1 5 9 4 8 3
1 5 9 4 8 3 7 2 6
8 3 7 2 6 1 5 9 4
2 6 1 5 9 4 8 3 7
5 9 4 8 3 7 2 6 1
3 7 2 6 1 5 9 4 8
6 1 5 9 4 8 3 7 2
9 4 8 3 7 2 6 1 5
EOF
  end
end
