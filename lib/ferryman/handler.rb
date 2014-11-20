module Ferryman
  class Handler
    def handle(message, object)
      request = JsonRpcObjects::Request.parse(message)
      result = object.send(request.method, *request.params)
      JsonRpcObjects::V20::Response.create(result, nil, id: request.id)
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
