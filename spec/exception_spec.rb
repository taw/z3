module Z3
  describe Exception do
    let(:solver) { Solver.new }

    it "names the error code Z3 signalled" do
      expect{ Solver.for_logic("QF_NO_SUCH_LOGIC") }
        .to raise_error(Z3::Exception, /\AZ3 library failed with error Z3_INVALID_ARG: /)
    end

    # The reason to ask Z3 for the message at all - the code alone would only say
    # Z3_INVALID_ARG, which doesn't tell you which argument or why
    it "includes what Z3 says went wrong" do
      expect{ Solver.for_logic("QF_NO_SUCH_LOGIC") }
        .to raise_error(Z3::Exception, /logic 'QF_NO_SUCH_LOGIC' is not recognized/)
    end

    it "includes parser errors, with the position of the problem" do
      expect{ solver.from_string("(assert (+ 1 true))") }
        .to raise_error(Z3::Exception, /\AZ3 library failed with error Z3_PARSER_ERROR: .*line 1 column \d+/)
    end

    # Parsing doesn't stop at the first problem, and all of them are worth reporting
    it "includes every parser error, one per line" do
      expect{ solver.from_string("(declare-const a Foo)(assert (> a b))") }
        .to raise_error(Z3::Exception, /unknown sort 'Foo'.*\n.*unknown constant a/)
    end

    # Z3 has nothing to add for some errors, and the message just restates the code
    it "works when Z3's message says no more than the code does" do
      expect{ solver.from_file("#{__dir__}/fixtures/no-such-file.smt2") }
        .to raise_error(Z3::Exception, /\AZ3 library failed with error Z3_FILE_ACCESS_ERROR: \w/)
    end

    # Not every failure is an argument Z3 rejects - this one is a solver that can't
    # answer the question at all
    it "reports errors Z3 raises as exceptions internally" do
      expect{ solver.trail }
        .to raise_error(Z3::Exception, /\AZ3 library failed with error Z3_EXCEPTION: \w/)
    end

    it "leaves the solver usable afterwards" do
      expect{ solver.from_string("(assert (+ 1 true))") }.to raise_error(Z3::Exception)
      solver.assert Z3.Int("a") == 1
      expect(solver).to be_satisfiable
    end

    it "raises Z3::Exception rather than crashing the process" do
      expect{ Solver.for_logic("QF_NO_SUCH_LOGIC") }.to raise_error(Z3::Exception)
      # The handler is installed once and has to survive being used
      expect{ Solver.for_logic("QF_NO_SUCH_LOGIC") }.to raise_error(Z3::Exception)
    end
  end
end
