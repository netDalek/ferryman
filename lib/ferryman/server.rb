module Ferryman
  class Server
    def initialize(redis, *channels)
      @redis = redis
      @response_redis = redis.dup
      @channels = channels
    end

    def receive(&block)
      @redis.subscribe(*@channels) do |on|
        on.message do |_, msg|
          process(msg, &block)
        end
      end
    end

    private

    def process(message, &block)
      response = execute(message, &block)
      if response.id
        @response_redis.rpush(response.id, response.to_json)
        @response_redis.del(response.id)
      end
    rescue ExitError
      @redis.unsubscribe
    end

    def execute(message)
      request = JsonRpcObjects::Request.parse(message)
      result = yield(request.method, request.params)
      JsonRpcObjects::V20::Response.create(result, nil, id: request.id)
    rescue ExitError
      raise
    rescue ArgumentError => e
      error = JsonRpcObjects::V20::Error.create(-32602, e)
      JsonRpcObjects::V20::Response.create(nil, error, id: request.id)
    rescue NoMethodError => e
      error = JsonRpcObjects::V20::Error.create(-32601, e)
      JsonRpcObjects::V20::Response.create(nil, error, id: request.id)
    rescue MultiJson::ParseError => e
      error = JsonRpcObjects::V20::Error.create(-32700, e)
      JsonRpcObjects::V20::Response.create(nil, error, id: request.id)
    rescue RuntimeError => e
      error = JsonRpcObjects::V20::Error.create(-32700, e)
      JsonRpcObjects::V20::Response.create(nil, error, id: request.id)
    end
  end

end
