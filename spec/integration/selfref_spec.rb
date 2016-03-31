describe "Self-Referential Aptitude Test" do
  it do
    expect("selfref").to have_output <<EOF
Q 1: D
Q 2: A
Q 3: D
Q 4: B
Q 5: E
Q 6: D
Q 7: D
Q 8: E
Q 9: D
Q10: A
Q11: B
Q12: A
Q13: D
Q14: B
Q15: A
Q16: D
Q17: B
Q18: A
Q19: B
Q20: E
EOF
  end
end
