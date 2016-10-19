describe "Regexp Crossword Solver" do
  let(:binary) { Pathname(__dir__) + "../../examples/regexp_crossword_solver" }

  examples = (Pathname(__dir__) + "../../examples/regexp_crossword")
             .children
             .select{|x| x.extname == ".txt"}
  examples.each do |example_path|
    describe example_path.basename.to_s do
      let(:example) { example_path.readlines.map(&:chomp) }
      let(:col_number) { example.index("") }
      let(:row_number) { example.size - col_number - 1 }
      # left to right
      let(:cols) { example.first(col_number) }
      # top to bottom
      let(:rows) { example.last(row_number) }

      it "matches output" do
        output_rows = `#{binary} #{example_path}`.split("\n").map(&:chomp)
        output_cols = output_rows.map(&:chars).transpose.map(&:join)
        expect(output_rows.size).to eq(rows.size)
        expect(output_cols.size).to eq(cols.size)
        output_rows.zip(rows).each do |s, rx|
          expect(s).to match Regexp.new(/\A(?:#{rx})\z/)
        end
        output_cols.zip(cols).each do |s, rx|
          expect(s).to match Regexp.new(/\A(?:#{rx})\z/)
        end
      end
    end
  end
end
