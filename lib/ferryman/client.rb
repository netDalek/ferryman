require 'timeout'

module Ferryman
  class Client
    class NoSubscriptions < RuntimeError; end

    def initialize(redis, channel, timeout = 1)
      @redis = redis
      @channel = channel
      @timeout = timeout
    end

    def servers_count
      @redis.client.call([:pubsub, :numsub, @channel]).last.to_i
    end

    def cast(method, *arguments)
      message = JsonRpcObjects::V20::Request.create(method, arguments).to_json
      @redis.publish(@channel, message)
    end

    def call(method, *arguments, timeout: nil)
      multicall(method, *arguments, timeout: timeout).tap do |responses|
        raise NoSubscriptions if responses.empty?
      end.first
    end

    def multicall(method, *arguments, timeout: nil)
      key = random_key
      message = JsonRpcObjects::V20::Request.create(method, arguments, id: key).to_json
      servers_count = @redis.publish(@channel, message)
      time_left = timeout || @timeout
      servers_count.to_i.times.map do
        time_before = Time.now
        _key, raw_response = @redis.blpop(key, timeout: time_left)
        time_after = Time.now
        time_left = time_left - (time_after - time_before)

        raise Timeout::Error, "timeout for method #{method} with arguments #{arguments}" if raw_response.nil?
        response = JsonRpcObjects::Response.parse(raw_response)
        response.result || raise(Ferryman::Error.new(response.error))
      end
    end

    private

    def random_key
      SecureRandom.hex(16)[0..7]
    end
  end
end
