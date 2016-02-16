describe Z3 do
  it "#version return version number of Z3 library" do
    expect(Z3.version).to match(/\A\d+\.\d+\.\d+\.\d+\z/)
  end
end
