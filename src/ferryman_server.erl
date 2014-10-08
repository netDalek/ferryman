-module(ferryman_server).

-export([
         start_link/5,
         put_reply/3
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(st, {
    sub,
    client,
    handler
}).

start_link(Host, Port, Db, Channels, Handler) ->
  gen_server:start_link(?MODULE, [Host, Port, Db, Channels, Handler], []).

put_reply(Pid, Id, Msg) ->
  gen_server:call(Pid, {put_reply, Id, Msg}).

%% ===================================================================
%% GEN SERVER
%% ===================================================================

init([Host, Port, Db, Channels, Handler]) ->
  error_logger:info_msg("start ferryman_server on redis on ~s:~w[~w] channels ~p", [Host, Port, Db, Channels]),
  {ok, Sub} = eredis_sub:start_link(Host, Port, ""),
  {ok, Client} = eredis:start_link(Host, Port, Db),
  eredis_sub:controlling_process(Sub),
  eredis_sub:subscribe(Sub, [list_to_binary(C) || C <- Channels]),
  {ok, #st{sub=Sub, client=Client, handler=Handler}}.

handle_cast(_Msg, St) ->
    {stop, error, St}.

handle_call({put_reply, Id, Msg}, _From, St) ->
    eredis:q(St#st.client, ["RPUSH", Id, Msg]),
    eredis:q(St#st.client, ["DEL", Id]),
    {reply, ok, St};
handle_call(stop, _From, St) ->
    {stop, normal, shutdown_ok, St};
handle_call(_Msg, _From, St) ->
    {stop, error, St}.

handle_info({message, _Channel, Message, _Pid}, St) ->
  error_logger:info_msg("ferryman_server receive message ~s", [Message]),
  Self = self(),
  spawn_link(fun() -> handle_request(Self, Message, St#st.handler) end),
  eredis_sub:ack_message(St#st.sub),
  {noreply, St};
handle_info(_Info, #st{sub = Sub} = St) ->
  eredis_sub:ack_message(Sub),
  {noreply, St}.

code_change(_OldVsn, St, _Extra) -> {ok, St}.

terminate(_Reason, _St) -> ok.

%% ===================================================================
%% PRIVATE
%% ===================================================================

handle_request(ParentPid, Message, Handler) ->
  case jsonrpc2:handle(Message, Handler, fun jiffy:decode/1, fun jiffy:encode/1) of
    noreply ->
      error_logger:info_msg("ferryman_server don't reply for cast message ~s", [Message]),
      nop;
    {reply, Msg} ->
      {MsgAttrs} = jiffy:decode(Msg),
      Id = proplists:get_value(<<"id">>, MsgAttrs),
      error_logger:info_msg("ferryman_server reply for message ~s", [Id]),
      put_reply(ParentPid, Id, Msg)
      % eredis:q(St#st.client, ["RPUSH", Id, Msg]),
      % eredis:q(St#st.client, ["DEL", Id])
  end.

