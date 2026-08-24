module Z3
  class Context
    attr_reader :_context

    # Z3 takes context creation time parameters through a config object, and the only
    # chance to set them is right here - see Z3.configure, which is the way in.
    def initialize(config = {})
      @_context = LowLevel.mk_context(config)
      # The error handler can only be installed on a context which exists, and this
      # is the moment it starts existing. `exception.rb` handed its block over at
      # require time, long before now.
      LowLevel.install_error_handler(@_context)
    end

    class << self
      def instance
        @instance ||= new(Z3.configuration)
      end

      # Whether anything has created the context yet. Z3.configure asks, because
      # context parameters set after this point can't do anything.
      def created?
        !@instance.nil?
      end
    end
  end
end
