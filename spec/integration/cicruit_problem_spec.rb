describe "Circuit Problems" do
  it do
    expect("circuit_problems").to have_output <<EOF
Problem 1
* I V = -5/4

Problem 2
* I V = -10
EOF
  end
end
