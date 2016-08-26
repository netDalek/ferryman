module Ferryman
  class AsyncCall
    def initialize(redis, timeout, method, key, servers_count)
      @redis = redis
      @timeout = timeout
      @method = method
      @key = key
      @servers_count = servers_count
    end

    def results(timeout = nil)
      time_left = timeout || @timeout
      @servers_count.to_i.times.map do
        time_before = Time.now
        _key, raw_response = @redis.blpop(@key, timeout: time_left.ceil)
        time_after = Time.now
        time_left = time_left - (time_after - time_before)
        time_left = 0 if time_left < 0

        raise Timeout::Error, "timeout for method #{@method} with arguments #{@arguments}" if raw_response.nil?
        response = JsonRpcObjects::Response.parse(raw_response)
        response.result || raise(Ferryman::Error.new(response.error))
      end
    end
  end
end
