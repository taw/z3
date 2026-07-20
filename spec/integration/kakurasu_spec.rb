describe "Kakurasu" do
  let(:binary) { Pathname(__dir__) + "../../examples/kakurasu" }

  it do
    expect("kakurasu").to have_output <<EOF
[ ][ ][X][ ][ ][ ][X][ ][ ][ ][ ][ ]
[ ][X][ ][X][ ][ ][ ][ ][ ][X][X][X]
[ ][X][X][X][ ][ ][X][ ][ ][ ][ ][ ]
[ ][X][X][ ][ ][X][X][X][X][ ][X][X]
[ ][X][ ][ ][ ][ ][ ][ ][ ][ ][ ][ ]
[ ][ ][X][ ][ ][ ][ ][X][ ][ ][X][ ]
[X][ ][ ][ ][ ][X][X][ ][ ][ ][X][X]
[ ][ ][ ][ ][ ][ ][X][ ][ ][ ][X][X]
[ ][ ][X][ ][ ][ ][ ][ ][ ][ ][X][ ]
[ ][ ][ ][ ][X][ ][X][ ][X][ ][X][ ]
[ ][ ][ ][ ][ ][X][X][ ][X][ ][X][ ]
[ ][ ][X][ ][X][ ][X][ ][X][ ][X][ ]
EOF
  end

  # Nothing in the rules requires a square board - row sums weight cells by
  # column index, column sums by row index, and the two are independent.
  # This 6x4 board has a unique solution.
  it "solves a non-square board" do
    board = Pathname(__dir__) + "../../examples/kakurasu-2.txt"
    expect(`#{binary} #{board}`).to eq(<<EOF)
[ ][X][X][X][X][X]
[ ][ ][X][ ][ ][X]
[ ][ ][ ][X][ ][ ]
[X][ ][X][ ][X][X]
EOF
  end
end
