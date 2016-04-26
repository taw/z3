describe Z3::Printer do
  it "numbers" do
    expect(Z3::IntSort.new.from_const(42).to_s).to eq("42")
    expect(Z3::IntSort.new.from_const(-42).to_s).to eq("-42")
  end
end
