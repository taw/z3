describe "Password Policy" do
  let(:binary) { Pathname(__dir__) + "../../examples/password_policy" }

  # The policy has plenty of shortest solutions, so the test checks the policy rather
  # than one particular password
  it "finds a shortest password satisfying the policy" do
    password = `#{binary}`.chomp
    expect(password.length).to eq(8)
    expect(password).to match(/[a-z]/)
    expect(password).to match(/[A-Z]/)
    expect(password).to match(/[0-9]/)
    expect(password).to match(/[!@\#$%^&*]/)
    expect(password).to match(/\A[a-zA-Z0-9!@\#$%^&*]+\z/)
    expect(password).to_not include("password")
  end
end
