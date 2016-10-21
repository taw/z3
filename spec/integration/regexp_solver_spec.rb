describe "Regexp Solver" do
  let(:binary) { Pathname(__dir__) + "../../examples/regexp_solver" }

  examples = [
    [3 ,'lol'],
    [3, '\d\d\d'],
    # [4, 'a*\Ab*\zc*'],
  ]

  examples.each do |length, rx|
    describe rx do
      it "matches output" do
        actual = `#{binary} #{length} '#{rx}'`.chomp
        expect(actual.size).to eq(length)
        expect(actual).to match Regexp.new(/\A(?:#{rx})\z/)
      end
    end
  end
end
