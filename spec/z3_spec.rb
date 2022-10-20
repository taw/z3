describe Z3 do
  it "#version return version number of Z3 library" do
    expect(Z3.version).to match(/\A\d+\.\d+\.\d+\.\d+\z/)
  end

  it "#version_at_least return if version matches" do
    version = Z3.version.split(".").map(&:to_i)
    expect(Z3.version_at_least?(*version)).to eq(true)
    expect(Z3.version_at_least?(*version[0,2])).to eq(true)
    expect(Z3.version_at_least?(*version[0,1])).to eq(true)
    expect(Z3.version_at_least?(version[0])).to eq(true)
    expect(Z3.version_at_least?(*version[0,2], 999)).to eq(false)
    expect(Z3.version_at_least?(999)).to eq(false)
  end
end
