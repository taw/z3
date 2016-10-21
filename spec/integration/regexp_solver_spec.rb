require "yaml"

describe "Regexp Solver" do
  let(:binary) { Pathname(__dir__) + "../../examples/regexp_solver" }

  examples = [
    [3 ,'lol'],
    [3, '\d\d\d'],
    [4, 'a*\Ab*\zc*'],
    [2, '^\n^\n'],
    [1, '(?=[ab])(?=[bc])[bd]'],
    [1, '(?=[ab])(?![bc])[ac]'],
    [2, '(?=a$)a\n'],
    [2, '(?=a\s$)a\n'],
  ]

  examples.each do |length, rx|
    describe rx do
      it "matches output" do
        actual_esc = `#{binary} #{length} '#{rx}'`.chomp
        actual = YAML.load(%Q(---\n"#{actual_esc}"\n)) # avoid eval
        expect(actual.size).to eq(length)
        expect(actual).to match Regexp.new(/\A(?:#{rx})\z/)
      end
    end
  end
end
