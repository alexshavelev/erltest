%%%-------------------------------------------------------------------
%%% @author alex_shavelev
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Apr 2016 17:45
%%%-------------------------------------------------------------------
-module(reader).
-author("alex_shavelev").

-include("records.hrl").

-define(TIME, 5).
-define(TIME_EMPTY, 500).

%% API
-export([
  start_link/0,
  worker/0
]).

start_link() ->
  Pid = spawn_link(?MODULE, worker, []),
  {ok, Pid}.

worker() ->
  case message_server:get_message() of
    {error, blocked} ->
      timer:apply_after(?TIME, ?MODULE, worker, []);

    {error, empty_queue} ->
      timer:apply_after(?TIME_EMPTY, ?MODULE, worker, []);

    #message{id = MessageId, text = TextMessage} = Message ->
      io:format("Message: id ~p text ~p~n", [MessageId, TextMessage]),
      message_server:delete_message(Message),
      timer:apply_after(?TIME, ?MODULE, worker, [])
  end.


