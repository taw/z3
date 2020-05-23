describe "Killer Sudoku" do
  it do
    expect("killer_sudoku").to have_output <<EOF
4 2 3 1
3 1 2 4
2 4 1 3
1 3 4 2
EOF
  end
end
