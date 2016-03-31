describe "LightUp" do
  it "can solve light up puzzle" do
    expect("light_up_solver").to have_output <<EOF
  * 0
*
x 2*x
  *3  *
* x*x*3
      *
 *1 *
EOF
  end
end
