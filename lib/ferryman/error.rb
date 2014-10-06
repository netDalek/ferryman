module Ferryman
  class Error < RuntimeError
    def initialize(json_rpc_error)
      @error = json_rpc_error
    end

    def message
      @error.message
    end

    def backtrace
      @error.data
    end
  end
end
