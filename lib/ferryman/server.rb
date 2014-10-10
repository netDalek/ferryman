module Ferryman
  class Server
    def initialize(redis, *channels)
      @handler = Handler.new
      @redis = redis
      @response_redis = redis.dup
      @channels = channels
    end

    def receive(obj)
      @redis.subscribe(*@channels) do |on|
        on.message do |_, msg|
          process(msg, obj)
        end
      end
    end

    private

    def process(message, obj)
      response = @handler.handle(message, obj)
      if response.id
        @response_redis.multi do
          @response_redis.rpush(response.id, response.to_json)
          @response_redis.expire(response.id, 60)
        end
      end
    end

  end
end
