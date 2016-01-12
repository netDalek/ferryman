require 'active_support'
require 'active_support/core_ext/class'
require 'logger'

module Ferryman
  class Server
    class_attribute :logger 
    self.logger = Logger.new(STDOUT)

    def initialize(redis, *channels)
      @handler = Handler.new
      @redis = redis
      @response_redis = redis.dup
      @channels = channels
    end

    def receive(obj)
      @redis.subscribe(*@channels) do |on|
        on.message do |_, msg|
          logger.info "[Ferryman::Server] received #{msg}"
          process(msg, obj)
        end
      end
    end

    private

    def process(message, obj)
      response = @handler.handle(message, obj)
      logger.info "[Ferryman::Server] response #{response.to_json}"
      if response.id
        @response_redis.multi do
          @response_redis.rpush(response.id, response.to_json)
          @response_redis.expire(response.id, 60)
        end
      end
    end

  end
end
