describe "Geometry Problem" do
  it do
    expect("geometry_problem").to have_output <<EOF
* a.x = 0
* a.y = -17.3205080756?
* b.x = 0
* b.y = 0
* c.x = 10
* c.y = 0
* d.x = 10
* d.y = -17.3205080756?
* |a-c| = -20
* |b-d| = 20
EOF
  end
end
