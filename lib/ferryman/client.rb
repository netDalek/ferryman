require 'timeout'

module Ferryman
  class Client
    class NoSubscriptions < RuntimeError; end

    attr_reader :redis, :channel, :timeout

    def initialize(redis, channel, timeout = 1)
      @redis = redis
      @channel = channel
      @timeout = timeout
    end

    def servers_count
      redis.client.call([:pubsub, :numsub, channel]).last.to_i
    end

    def queue
      redis.llen(channel)
    end

    def call(method, *arguments)
      Ferryman::Rpc::Sync.new(redis, channel, method, arguments, timeout)
    end

    def cast(method, *arguments)
      Ferryman::Rpc::Async.new(redis, channel, method, arguments, timeout)
    end
  end
end
