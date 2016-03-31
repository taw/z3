describe "Geometry Problem" do
  it do
    expect("geometry_problem").to have_output <<EOF
* a.x = 0.0
* a.y = (root-obj (+ (^ x 2) (- 300)) 1)
* b.x = 0.0
* b.y = 0.0
* c.x = 10.0
* c.y = 0.0
* d.x = 10.0
* d.y = (root-obj (+ (^ x 2) (- 300)) 1)
* |a-c| = (- 20.0)
* |b-d| = 20.0
EOF
  end
end
