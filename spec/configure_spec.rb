require "rbconfig"
require "open3"

# Z3 reads these parameters while it's creating the context, and a context is created
# once per process and can't be put back - so most of this has to happen somewhere
# else, one fresh process per configuration. `spec/upstream_bugs_spec.rb` runs scripts
# for its own reasons, and this is the same trick.
module Z3
  describe "Z3.configure" do
    def output_of(ruby_code)
      out, _status = Open3.capture2e(
        RbConfig.ruby, "-I#{__dir__}/../lib", "-rz3", "-e", ruby_code,
      )
      out
    end

    # Everything else here depends on this: if requiring the gem created the context,
    # there would be no moment at which #configure could work. The error handler is
    # what used to force it, and it now waits for the context instead of making one.
    it "doesn't create the context until something needs it" do
      expect(output_of(<<~RUBY)).to eq("false\nfalse\ntrue\n")
        p Z3::Context.created?
        Z3.version
        p Z3::Context.created?
        Z3.Int("x")
        p Z3::Context.created?
      RUBY
    end

    it "starts out configuring nothing" do
      expect(output_of('p Z3.configuration')).to eq("{}\n")
    end

    # `proof` is the reason this method exists: Z3.set_param can't do it, and says so.
    it "sets a parameter with no other way in" do
      expect(output_of(<<~RUBY)).to eq("unsat\ntrue\n")
        Z3.configure(proof: true)
        solver = Z3::Solver.new
        x = Z3.Int("x")
        solver.assert x > 0
        solver.assert x < 0
        puts solver.check
        # Solver#proof doesn't exist yet - a proof is a term in Z3's own proof
        # calculus, which is its own project. That Z3 has one to give is the claim.
        puts !Z3::LowLevel.solver_get_proof(solver).null?
      RUBY
    end

    it "and without it Z3 has no proof to give" do
      expect(output_of(<<~RUBY)).to eq("unsat\nthere is no current proof\n")
        solver = Z3::Solver.new
        x = Z3.Int("x")
        solver.assert x > 0
        solver.assert x < 0
        puts solver.check
        begin
          Z3::LowLevel.solver_get_proof(solver)
        rescue Z3::Exception => e
          puts e.message[/there is no current proof/]
        end
      RUBY
    end

    # Not every parameter is a Boolean. `encoding` decides how wide Z3's alphabet is,
    # so it decides which characters can exist at all.
    it "takes a value which isn't a Boolean" do
      script = <<~RUBY
        Z3.configure(encoding: ARGV[0])
        solver = Z3::Solver.new
        solver.assert Z3::CharSort.new.var("c").to_i > 0xFFFF
        puts solver.check
      RUBY
      expect(output_of(script.sub("ARGV[0]", '"unicode"'))).to eq("sat\n")
      expect(output_of(script.sub("ARGV[0]", '"bmp"'))).to eq("unsat\n")
    end

    # Names arrive as Strings whether they were written as Symbols or not, so the two
    # spellings are the same parameter and the second call overrides the first.
    it "merges what it's told, so a later call wins" do
      expect(output_of(<<~RUBY)).to eq("true\n")
        Z3.configure(proof: false, model: false)
        Z3.configure("proof" => true)
        puts Z3.configuration == {"proof" => true, "model" => false}
      RUBY
    end

    # A parameter set too late does nothing at all on Z3's side, which is worth an
    # exception rather than a silence - the same call is fine a line earlier.
    it "raises once the context exists" do
      Z3.Int("configure_spec_forces_the_context")
      expect { Z3.configure(proof: true) }.to raise_error(
        Z3::Exception, /Z3 context already exists/
      )
    end

    it "refuses a parameter Z3 doesn't have" do
      expect { Z3.configure(no_such_parameter: true) }.to raise_error(
        Z3::Exception, /Unknown context parameter `no_such_parameter'/
      )
    end

    it "refuses anything which isn't a Hash" do
      expect { Z3.configure("proof") }.to raise_error(
        Z3::Exception, "Hash of context parameters required"
      )
    end
  end
end
