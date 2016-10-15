module Ferryman
  class Handler
    def handle(message, object)
      puts "message: #{message}"
      request = JsonRpcObjects::Request.parse(message)
      if request.method == "headcheck"
        JsonRpcObjects::V20::Response.create(primary_channel, nil, id: request.id)
      else
        result = object.send(request.method, *request.params)
        JsonRpcObjects::V20::Response.create(result, nil, id: request.id)
      end
    rescue ArgumentError => e
      error = JsonRpcObjects::V20::Error.create(-32602, e)
      JsonRpcObjects::V20::Response.create(nil, error, id: request.id)
    rescue NoMethodError => e
      error = JsonRpcObjects::V20::Error.create(-32601, e)
      JsonRpcObjects::V20::Response.create(nil, error, id: request.id)
    rescue MultiJson::ParseError => e
      error = JsonRpcObjects::V20::Error.create(-32700, e)
      JsonRpcObjects::V20::Response.create(nil, error, id: request.id)
    rescue StandardError => e
      error = JsonRpcObjects::V20::Error.create(-32700, e)
      JsonRpcObjects::V20::Response.create(nil, error, id: request.id)
    end
  end
end
