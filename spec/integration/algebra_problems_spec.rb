describe "Algebra Problems" do
  it do
    expect("algebra_problems").to have_output <<EOF
Solution to problem 01:
Solution to problem 03:
* x = (- 22.0)
* |-6| = 6.0
* |x-2| = 24.0
Solution to problem 04:
* ax = (- 4.0)
* ay = (- 5.0)
* bx = (- 1.0)
* by = (- 1.0)
* |a-b| = 5.0
Solution to problem 05:
* x = (/ 9.0 2.0)
* y = 0.0
Solution to problem 06:
* answer = 6.0
* x1 = 1.0
* x2 = 2.0
* y1 = 7.0
* y2 = 13.0
Solution to problem 10:
* x = 1.0
* |-2x + 2| = 0.0
EOF
  end
end
