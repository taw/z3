module Z3
  describe Tactic do
    it "constructors" do
      expect(Tactic.fail).to be_a Tactic
      expect(Tactic.fail_if_not_decided).to be_a Tactic
      expect(Tactic.skip).to be_a Tactic
    end
  end
end
