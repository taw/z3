describe "Skysrapers" do
  it do
    expect("skyscrapers").to have_output <<EOF
2 4 1 3
4 2 3 1
3 1 4 2
1 3 2 4
EOF
  end
end
