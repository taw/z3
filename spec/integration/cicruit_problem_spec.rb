describe "Circuit Problems" do
  it do
    expect("circuit_problems").to have_output <<EOF
Problem 1
* I V = -5/4

Problem 2
* I V = -10

Problem 3
* I L = -1
* I V = -1
* I L = -1/2
* I V = -1/2
* I L = 0
* I V = 0
* I L = -1/2
* I V = 1/2
* I L = -1
* I V = 1
EOF
  end
end
