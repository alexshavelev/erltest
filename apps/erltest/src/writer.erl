%%%-------------------------------------------------------------------
%%% @author alex_shavelev
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Apr 2016 17:45
%%%-------------------------------------------------------------------
-module(writer).
-author("alex_shavelev").
-include("records.hrl").

-define(TIME, 100).

%% API
-export([
  start_link/0,
  worker/0
]).

start_link() ->
  supervisor:start_child(reader_sup, []),
  supervisor:start_child(reader_sup, []),
  Pid = spawn_link(?MODULE, worker, []),
  {ok, Pid}.

worker() ->
  Message = #message{id = util:get_random_id(), text = <<"some test text">>},
  message_server:send_message(Message),
  timer:apply_after(?TIME, ?MODULE, worker, []).
