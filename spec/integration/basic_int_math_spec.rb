describe "Basic Integer Math" do
  it do
    expect("basic_int_math").to have_output <<EOF
Checking if (a+b)(a-b)==a*a-b*b
Proven
Checking if a+b >= a
Counterexample exists
* b = -1
Checking if a+b >= a if a,b >= 0
Proven
EOF
  end
end
