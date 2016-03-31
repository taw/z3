describe "Verbal Arithmetic" do
  it do
    expect("verbal_arithmetic").to have_output <<EOF
[["S", 9], ["E", 5], ["N", 6], ["D", 7]]
[["M", 1], ["O", 0], ["R", 8], ["E", 5]]
[["M", 1], ["O", 0], ["N", 6], ["E", 5], ["Y", 2]]
EOF
  end
end
