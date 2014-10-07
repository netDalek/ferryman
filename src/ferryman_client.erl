-module(ferryman_client).

-export([
         call/4,
         cast/4
        ]).

cast(Redis, Channel, Method, Params) ->
  Req = jsonrpc2_client:create_request({Method, Params}),
  JsonReq = jiffy:encode(Req),
  eredis:q(Redis, ["PUBLISH", Channel, JsonReq]).

call(Redis, Channel, Method, Params) ->
  [H | _] = multicall(Redis, Channel, Method, Params),
  H.

multicall(Redis, Channel, Method, Params) ->
  Id = random_key(),
  Req = jsonrpc2_client:create_request({Method, Params, Id}),
  JsonReq = jiffy:encode(Req),
  {ok, ServersCount} = eredis:q(Redis, ["PUBLISH", Channel, JsonReq]),
  [get_value(Redis, Id) || _ <- lists:seq(1, binary_to_integer(ServersCount))].

get_value(Redis, Id) ->
  {ok, [_Key, Value]} = eredis:q(Redis, ["BLPOP", Id, 1000]),
  {Response} = jiffy:decode(Value),
  case proplists:get_value(<<"result">>, Response) of
    undefined -> {error, proplists:get_value(<<"error">>, Response)};
    Result -> {ok, Result}
  end.

random_key() ->
  base64:encode(crypto:strong_rand_bytes(10)).

