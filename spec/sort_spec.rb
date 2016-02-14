describe Z3::Sort do
  it "create Bool sort" do
    expect(Z3::Sort.bool.to_s).to eq("Bool")
    expect(Z3::Sort.bool.inspect).to eq("Z3::Sort<Bool>")
  end

  it "create Int sort" do
    expect(Z3::Sort.int.to_s).to eq("Int")
    expect(Z3::Sort.int.inspect).to eq("Z3::Sort<Int>")
  end

  it "create Real sort" do
    expect(Z3::Sort.real.to_s).to eq("Real")
    expect(Z3::Sort.real.inspect).to eq("Z3::Sort<Real>")
  end

  it "supports ==" do
    expect(Z3::Sort.bool).to eq(Z3::Sort.bool)
    expect(Z3::Sort.int).to eq(Z3::Sort.int)
    expect(Z3::Sort.bool).to_not eq(Z3::Sort.int)
  end
end
