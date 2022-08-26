# There are multiple solutions, so this test is nondeterministic
# This is what Z3 4.8.13 returns
describe "Knights Swap Puzzle" do
  it do
    expect("knights_puzzle").to have_output_matching_saved_example
  end
end
