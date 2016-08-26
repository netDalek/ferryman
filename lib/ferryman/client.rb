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

    def async_call(method, *arguments)
      key = random_key
      message = JsonRpcObjects::V20::Request.create(method, arguments, id: key).to_json
      servers_count = @redis.publish(@channel, message)
      Ferryman::AsyncCall.new(@redis, @timeout, method, key, servers_count)
    end

    def multicall(method, *arguments, timeout: nil)
      async_call(method, *arguments).results
    end

    private

    def random_key
      SecureRandom.hex(16)[0..7]
    end
  end
end
