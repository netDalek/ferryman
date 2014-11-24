-module(ferryman_client).

-export([
         cast/4,
         call/5,
         call/4,
         multicall/5,
         multicall/4
        ]).

cast(Redis, Channel, Method, Params) ->
  Req = jsonrpc2_client:create_request({Method, Params}),
  JsonReq = jiffy:encode(Req),
  eredis:q(Redis, ["PUBLISH", Channel, JsonReq]).

call(Redis, Channel, Method, Params) ->
  call(Redis, Channel, Method, Params, 1).

call(Redis, Channel, Method, Params, Timeout) ->
  [H | _] = multicall(Redis, Channel, Method, Params, Timeout),
  H.

multicall(Redis, Channel, Method, Params) ->
  multicall(Redis, Channel, Method, Params, 1).

multicall(Redis, Channel, Method, Params, Timeout) ->
  Id = random_key(),
  Req = jsonrpc2_client:create_request({Method, Params, Id}),
  JsonReq = jiffy:encode(Req),
  {ok, ServersCount} = eredis:q(Redis, ["PUBLISH", Channel, JsonReq]),
  [get_value(Redis, Id, Timeout) || _ <- lists:seq(1, list_to_integer(binary_to_list(ServersCount)))].

get_value(Redis, Id, Timeout) ->
  {ok, [_Key, Value]} = eredis:q(Redis, ["BLPOP", Id, Timeout]),
  {Response} = jiffy:decode(Value),
  case proplists:get_value(<<"result">>, Response) of
      undefined ->
        {Error} = proplists:get_value(<<"error">>, Response),
        ErrorCode = proplists:get_value(<<"code">>, Error),
        ErrorMessage = proplists:get_value(<<"message">>, Error),
        {error, ErrorCode, ErrorMessage};
      Result ->
        {ok, Result}
  end.

random_key() ->
  base64:encode(crypto:strong_rand_bytes(10)).

