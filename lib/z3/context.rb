module Z3
  class Context
    attr_reader :_context
    def initialize
      @_context = LowLevel.mk_context
    end

    def self.instance
      @instance ||= new
    end
  end
end
