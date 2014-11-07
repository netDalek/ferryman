module Ferryman
  class Error < RuntimeError
    def initialize(json_rpc_error)
      @error = json_rpc_error
    end

    def message
      "#{@error.message} #{@error.data.inspect}"
    end
  end
end
