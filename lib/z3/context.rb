class Z3::Context
  attr_reader :_context
  def initialize
    @_context = Z3::Core.Z3_mk_context
  end

  def self.instance
    @instance ||= new
  end

  def self._context
    instance._context
  end
end
