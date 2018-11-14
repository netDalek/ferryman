require 'active_support/core_ext/module'

module Ferryman
  module Rpc
    class Result
      attr_reader :message, :redis, :key, :default_timeout, :results_count, :order

      def initialize(message, redis, key, default_timeout, results_count, order = nil)
        @message = message
        @redis = redis
        @key = key
        @default_timeout = default_timeout
        @results_count = results_count
        @order = order
      end

      def channel
        message.channel
      end

      def result(timeout = nil)
        results(timeout).first
      end

      def results(timeout = nil)
        timeout ||= default_timeout

        time_left = timeout
        results_count.times.map do
          time_before = Time.now
          _key, raw_response = redis.blpop(key, timeout: time_left.ceil)
          time_after = Time.now
          time_left = time_left - (time_after - time_before)
          time_left = 0 if time_left < 0

          raise Ferryman::TimeoutError.new(message, timeout) if raw_response.nil?
          response = JsonRpcObjects::Response.parse(raw_response)
          response.result || raise(Ferryman::Error.new(message, response.error))
        end
      end
    end
  end
end
