-module(ferryman_test).

-include_lib("eunit/include/eunit.hrl").


handler(<<"test">>, []) -> ok;
handler(_, _) -> throw(method_not_found).

rpc_test() ->
  ferryman_server:start_link("127.0.0.1", 6379, 0, ["a2p"], fun handler/2),
  {ok, Redis} = eredis:start_link(),
  {ok, R1} = ferryman_client:call(Redis, "a2p", test, []),
  ?assertEqual(<<"ok">>, R1),
  {error, -32601, <<"Method not found.">>} = ferryman_client:call(Redis, "a2p", dd, []).
