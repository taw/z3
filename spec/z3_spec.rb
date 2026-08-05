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

  # The rewriter's own parameters, nothing to do with the global ones below
  describe "simplify parameters" do
    it "#simplify_param_descrs describes what AST#simplify takes" do
      descrs = Z3.simplify_param_descrs
      expect(descrs).to be_a(Z3::ParamDescrs)
      expect(descrs.names).to include("som", "arith_lhs", "blast_distinct", "max_steps")
      expect(descrs.kind("som")).to eq(:bool)
      expect(descrs.kind("max_steps")).to eq(:uint)
      expect(descrs.documentation("som")).to include("sum-of-monomials")
    end

    # Z3 offers this as one block of text, where ParamDescrs takes them one at a time
    it "#simplify_help describes the same set" do
      expect(Z3.simplify_help).to include("som", "arith_lhs")
      expect(Z3.simplify_help.lines.size).to eq(Z3.simplify_param_descrs.size)
    end

    it "is not the global parameter set" do
      expect(Z3.param_descrs.names).to_not include("som")
      expect(Z3.simplify_param_descrs.names).to_not include("proof")
    end
  end

  describe "global parameters" do
    # Process wide state, so nothing may leak out of an example
    after { Z3.reset_params }

    it "#get_param reads one back" do
      expect(Z3.get_param("well_sorted_check")).to eq("false")
      expect(Z3.get_param("timeout")).to match(/\A\d+\z/)
    end

    it "#get_param is nil for a parameter Z3 doesn't have" do
      expect(Z3.get_param("no_such_parameter")).to eq(nil)
    end

    # Z3 answers an unknown name with a warning and a dump of every legal parameter,
    # all of it on stderr and none of it an error, so a typo would set nothing and
    # say nothing. Params checks its own names for the same reason.
    it "#set_param raises on a parameter Z3 doesn't have" do
      expect { Z3.set_param("no_such_parameter", true) }
        .to raise_error(Z3::Exception, "Unknown parameter `no_such_parameter'")
    end

    # There's no way to ask a module which parameters it has, so those are taken at
    # face value. `smt.qi.cost` is a string parameter, which is also the one kind
    # Params can't set - Z3 has no API for it - so this is the only way to set one.
    it "takes a module qualified name on trust" do
      expect(Z3.set_param("smt.qi.cost", "(+ weight generation)")).to eq("(+ weight generation)")
    end

    it "#set_param round trips through #get_param" do
      expect(Z3.set_param("well_sorted_check", true)).to eq(true)
      expect(Z3.get_param("well_sorted_check")).to eq("true")
    end

    # Z3's own interface to these is strings both ways
    it "hands the value back as a String, whatever it was set as" do
      Z3.set_param(:timeout, 5000)
      expect(Z3.get_param("timeout")).to eq("5000")
    end

    it "names are case insensitive, and take Symbols" do
      Z3.set_param(:well_sorted_check, true)
      expect(Z3.get_param("WELL_SORTED_CHECK")).to eq("true")
      expect(Z3.get_param(:well_sorted_check)).to eq("true")
    end

    it "module qualified names are read the same way" do
      expect(Z3.get_param("pp.decimal")).to eq("false")
    end

    it "#reset_params puts them all back" do
      Z3.set_param("well_sorted_check", true)
      Z3.set_param("timeout", 5000)
      expect(Z3.reset_params).to eq(nil)
      expect(Z3.get_param("well_sorted_check")).to eq("false")
      expect(Z3.get_param("timeout")).to_not eq("5000")
    end

    it "#param_descrs describes them" do
      descrs = Z3.param_descrs
      expect(descrs).to be_a(Z3::ParamDescrs)
      expect(descrs.names).to include("proof", "timeout", "well_sorted_check")
      expect(descrs.kind("timeout")).to eq(:uint)
      expect(descrs.kind("proof")).to eq(:bool)
      expect(descrs.documentation("proof")).to include("proof generation")
      # Only the unqualified ones - the modules describe theirs separately, and Z3
      # offers no way to reach those
      expect(descrs).to_not include("pp.decimal")
    end
  end
end
