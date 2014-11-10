module Ferryman
  class Error < RuntimeError
    def initialize(json_rpc_error)
      @error = json_rpc_error
    end

    def message
      @error.message
    end

    def data
      @error.data
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
