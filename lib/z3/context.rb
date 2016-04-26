class Z3::Context
  attr_reader :_context
  def initialize
    @_context = Z3::LowLevel.mk_context(Z3::LowLevel.mk_config)
  end

  def self.instance
    @instance ||= new
  end
end
