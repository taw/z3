describe "Insertion Sort Proof" do
  it do
    expect("insertion_sort_proof").to have_output <<EOF
lemma: inserting into a sorted list leaves it sorted
  proved: nil
  proved: cons
theorem: isort returns a sorted list
  proved: nil
  proved: cons
lemma: inserting a value adds one to its count and changes no other
  proved: nil
  proved: cons
theorem: isort is a permutation - every value occurs as often as before
  proved: nil
  proved: cons
and running it: [3, 1, 4, 1, 5] -> [1, 1, 3, 4, 5]
EOF
  end
end
