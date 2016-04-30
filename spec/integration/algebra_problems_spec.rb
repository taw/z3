describe "Algebra Problems" do
  it do
    expect("algebra_problems").to have_output <<EOF
Solution to problem 01:
Solution to problem 03:
* x = -22
* |-6| = 6
* |x-2| = 24
Solution to problem 04:
* ax = -4
* ay = -5
* bx = -1
* by = -1
* |a-b| = 5
Solution to problem 05:
* x = 9/2
* y = 0
Solution to problem 06:
* answer = 6
* x1 = 1
* x2 = 2
* y1 = 7
* y2 = 13
Solution to problem 10:
* x = 1
* |-2x + 2| = 0
EOF
  end
end
