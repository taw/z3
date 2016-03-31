describe "Bridges" do
  it "can solve bridges puzzle" do
    expect("bridges_solver").to have_output <<EOF

 3========6========4
 |        ‖        ‖
 |        ‖        ‖
 |  1     ‖        ‖
 |  |     ‖        ‖
 |  |     ‖        ‖
 |  |     4=====4  ‖
 |  |           ‖  ‖
 |  |           ‖  ‖
 |  |           ‖  ‖
 |  |           ‖  ‖
 |  |           ‖  ‖
 |  |  1-----3  ‖  ‖
 |  |        ‖  ‖  ‖
 |  |        ‖  ‖  ‖
 1  |        ‖  2  ‖
    |        ‖     ‖
    |        ‖     ‖
    3========5-----3

EOF
  end
end
