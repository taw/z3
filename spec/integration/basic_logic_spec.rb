describe "Basic Logic" do
  it "can solve basic logic problems" do
    expect("basic_logic").to have_output <<EOF
Checking if true == true
Proven
Checking if true == false
Counterexample exists
Proving ~(a & b) == (~a | ~b)
Proven
Proving ~(a | b) == (~a & ~b)
Proven
EOF
  end
end
