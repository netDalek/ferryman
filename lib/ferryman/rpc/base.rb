module Ferryman
  module Rpc
    class Base
      attr_reader :redis, :channel, :method, :arguments, :timeout

      def initialize(redis, channel, method, arguments, timeout)
        @redis = redis
        @channel = channel
        @method = method
        @arguments = arguments
        @timeout = timeout
      end

      def to_s
        "RPC to #{redis.id} channel #{channel} method #{method} with arguments #{arguments}"
      end

      def publish
        redis.publish(channel, rpc_message)
      end

      def push
        redis.lpush(channel, rpc_message)
      end

      def key
        nil
      end

      private

      def rpc_message
        JsonRpcObjects::V20::Request.create(method, arguments, id: key).to_json
      end
    end
  end
end
