describe "Eulero" do
  it do
    expect("eulero").to have_output <<EOF
C2 B4 D5 A1 E3
D1 A2 B3 E5 C4
E4 D3 C1 B2 A5
B5 E1 A4 C3 D2
A3 C5 E2 D4 B1
EOF
  end
end
