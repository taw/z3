describe "Kinematics Problems" do
  it do
    expect("kinematics_problems").to have_output <<EOF
Solution to problem 01:
* a = 16/5
* d = 215168/125
* t = 164/5
Solution to problem 02:
* a = 2200000/271441
* d = 110
* t = 521/100
Solution to problem 03:
* a = 981/100
* d = 165789/5000
* t = 13/5
* v = 12753/500
Solution to problem 04:
* a = 2760/247
* d = 79781/1000
* t = 247/100
* ve = 461/10
* vs = 37/2
Solution to problem 05:
* a = 167/100
* d = 7/5
* t = 1.2948539325?
Solution to problem 06:
* a = 14800/61
* d = 20313/50
* t = 183/100
* v = 444
Solution to problem 07:
* a = 5041/7080
* d = 177/5
* t = 708/71
* v = 71/10
Solution to problem 08:
* a = 3
* d = 4225/6
* t = 65/3
* v = 65
Solution to problem 09:
* d = 714/25
* t = 51/20
* v = 112/5
Solution to problem 10:
* a = -981/100
* d = 131/50
* t = 0.7308548609?
* v = 7.1696861856?
EOF
  end
end
