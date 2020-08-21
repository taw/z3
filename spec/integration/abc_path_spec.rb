# There are multiple solutions, so this test is nondeterministic
describe "ABC Path" do
  it do
    expect("abc_path").to have_output <<'EOF'
C O R D F B U

N o-n l-k-j L
  | |/    |
G p m g-f i I
  |    x /
Q q-r e h b H
   /  |  /|
V s v d-c a S
   x \
T u-t w-x-y X

J P M W K Y E
EOF
  end
end
