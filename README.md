# Ferryman

This is RPC realisation for ruby and erlang. It uses redis and JSON-RPC prothocol.
It uses redis pub/sub to send reqests and redis list for responses

It supports only JSON-RPC 2.0 version

You should remember that all data serialized to json, so all symbols and atoms become strings and binary.

##Ruby

###Server

```
class RemoteProcedures
  def add(a, b)
    a + b
  end
end
server = Ferryman::Server.new(Redis.new, "channel")
server.receive(RemoteProcedures.new)
```
You can pass more than one channel. 

###Client
```
timeout = 1.second
client = Ferryman::Client.new(Redis.new, "channel", timeout)
client.call(:sum, 1, 2) #3 or Ferryman::Client::NoSubscription exception
client.multicall(:sum, 1, 2) #[3] or []
client.cast(:sum, 1, 2) #1 - amount of subscribers
```

##Erlang

###Server
```
handler(<<"add">>, [A, B]) -> A + B;
handler(_, _) -> throw(method_not_found).

ferryman_server:start_link("127.0.0.1", 6379, 0, ["channel"], fun handler/2),
```

###Client
```
{ok, Redis} = eredis:start_link(),
ferryman_client:call(Redis, "channel", add, [1,2]), %3
ferryman_client:call(Redis, "channel", no_method, []). %{error, -32601, <<"Method not found.">>}
```

See more examples in tests
