describe "Cats Organized Neatly" do
  it do
    expect("cats_organized_neatly").to have_output <<EOF
.ffffbbb
.fdddbbb
aadddbbb
aadddbbe
aagggcee
aagggcce
aagggcc.
..gggcc.
EOF
  end
end
