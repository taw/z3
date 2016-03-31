describe "Bit Tricks" do
  it do
    expect("bit_tricks").to have_output <<EOF
Validating sign trick:
Proven
Validating sign trick:
Proven
Validating abs without branching, version 1
Proven
Validating abs without branching, version 2
Proven
Validating min without branching
Proven
Validating max without branching
Proven
Validating is power of two
Proven
EOF
  end
end
