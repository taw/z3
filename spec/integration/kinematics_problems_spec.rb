describe "Kinematics Problems" do
  let(:executable) { "#{__dir__}/../../examples/kinematics_problems" }
  it "can solve kinematics problems" do
    expect(IO.popen(executable).read).to eq <<EOF
Solution to problem 01:
* a = (/ 16.0 5.0)
* d = (/ 215168.0 125.0)
* t = (/ 164.0 5.0)
Solution to problem 02:
* a = (/ 2200000.0 271441.0)
* d = 110.0
* t = (/ 521.0 100.0)
Solution to problem 03:
* a = (/ 981.0 100.0)
* d = (/ 165789.0 5000.0)
* t = (/ 13.0 5.0)
* v = (/ 12753.0 500.0)
Solution to problem 04:
* a = (/ 2760.0 247.0)
* d = (/ 79781.0 1000.0)
* t = (/ 247.0 100.0)
* ve = (/ 461.0 10.0)
* vs = (/ 37.0 2.0)
Solution to problem 05:
* a = (/ 167.0 100.0)
* d = (/ 7.0 5.0)
* t = (root-obj (+ (* 167 (^ x 2)) (- 280)) 2)
Solution to problem 06:
* a = (/ 14800.0 61.0)
* d = (/ 20313.0 50.0)
* t = (/ 183.0 100.0)
* v = 444.0
Solution to problem 07:
* a = (/ 5041.0 7080.0)
* d = (/ 177.0 5.0)
* t = (/ 708.0 71.0)
* v = (/ 71.0 10.0)
Solution to problem 08:
* a = 3.0
* d = (/ 4225.0 6.0)
* t = (/ 65.0 3.0)
* v = 65.0
Solution to problem 09:
* d = (/ 714.0 25.0)
* t = (/ 51.0 20.0)
* v = (/ 112.0 5.0)
Solution to problem 10:
* a = (- (/ 981.0 100.0))
* d = (/ 131.0 50.0)
* t = (root-obj (+ (* 981 (^ x 2)) (- 524)) 2)
* v = (root-obj (+ (* 2500 (^ x 2)) (- 128511)) 2)
EOF
  end
end
