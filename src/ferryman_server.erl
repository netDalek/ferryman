-module(ferryman_server).

-export([
         start_link/5,
         stop/0
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(st, {
    sub = undefined,
    client,
    handler
}).

start_link(Host, Port, Db, Channels, Handler) ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [Host, Port, Db, Channels, Handler], []).

stop() ->
    gen_server:call(?MODULE, stop).

%% ===================================================================
%% GEN SERVER
%% ===================================================================

init([Host, Port, Db, Channels, Handler]) ->
  {ok, Sub} = eredis_sub:start_link(Host, Port, ""),
  {ok, Client} = eredis:start_link(Host, Port, Db),
  eredis_sub:controlling_process(Sub),
  eredis_sub:subscribe(Sub, [list_to_binary(C) || C <- Channels]),
  {ok, #st{sub=Sub, client=Client, handler=Handler}}.

handle_cast(_Msg, St) ->
    {stop, error, St}.

handle_call(stop, _From, St) ->
    {stop, normal, shutdown_ok, St};
handle_call(_Msg, _From, St) ->
    {stop, error, St}.

handle_info({message, _Channel, Message, _Pid}, St) ->
  case jsonrpc2:handle(Message, St#st.handler, fun jiffy:decode/1, fun jiffy:encode/1) of
    noreply -> nop;
    {reply, Msg} ->
      {MsgAttrs} = jiffy:decode(Msg),
      Id = proplists:get_value(<<"id">>, MsgAttrs),
      eredis:q(St#st.client, ["RPUSH", Id, Msg]),
      eredis:q(St#st.client, ["DEL", Id])
  end,
  eredis_sub:ack_message(St#st.sub),
  {noreply, St};
handle_info(_Info, #st{sub = Sub} = St) ->
  eredis_sub:ack_message(Sub),
  {noreply, St}.

code_change(_OldVsn, St, _Extra) -> {ok, St}.

terminate(_Reason, _St) -> ok.
