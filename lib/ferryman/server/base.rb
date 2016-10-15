require 'active_support'
require 'active_support/core_ext/class'
require 'logger'

module Ferryman
  module Server
    class Base
      class_attribute :logger 
      self.logger = Logger.new(STDOUT)

      def initialize(redis, *channels)
        @handler = Handler.new
        @redis = redis
        @response_redis = redis.dup
        @channels = channels
      end

      private

      def primary_channel
        @channels.first
      end

      def process(message, obj)
        response = @handler.handle(message, obj)
        logger.info "[Ferryman::Server] response #{response.to_json}"
        respond(response)
      end

      def respond(response)
        if response.id
          @response_redis.multi do
            @response_redis.rpush(response.id, response.to_json)
            @response_redis.expire(response.id, 60)
          end
        end
      end
    end
  end
end
