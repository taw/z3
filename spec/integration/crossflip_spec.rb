describe "CrossFlip" do
  it do
    expect("crossflip").to have_output <<EOF
[x] [ ] [ ] [ ]
[ ] [x] [ ] [x]
EOF
  end
end
