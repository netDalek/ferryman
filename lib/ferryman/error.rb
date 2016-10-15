module Ferryman
  class TimeoutError < Timeout::Error
    def initialize(rpc_message, timeout)
      @rpc_message = rpc_message
      @timeout = timeout
    end

    def message
      "#{@rpc_message} failed with timeout '#{@timeout}'"
    end

    def inspect
      "#<#{self.class}: #{message}>"
    end

    def to_s
      message
    end
  end

  class Error < RuntimeError
    def initialize(rpc, json_rpc_error)
      @rpc = rpc.to_s
      @error = json_rpc_error
    end

    def message
      "#{@rpc} failed with error '#{@error.message}'"
    end

    def data
      @error.data
    end

    def inspect
      "#<#{self.class}: #{message}>"
    end

    def to_s
      message
    end

    def backtrace
      if super().is_a?(Array) && @error.data.is_a?(Array) && @error.data.all?{|e| e.is_a?(String)}
        @error.data + super()
      else
        super()
      end
    end
  end
end
