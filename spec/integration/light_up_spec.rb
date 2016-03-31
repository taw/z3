describe "Light Up" do
  it do
    expect("light_up").to have_output <<EOF
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
