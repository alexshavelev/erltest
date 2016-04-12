%%%-------------------------------------------------------------------
%%% @author alex_shavelev
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Apr 2016 10:44
%%%-------------------------------------------------------------------
-module(message_server).
-author("alex_shavelev").

-behaviour(gen_server).

-include("records.hrl").

%% API
-export([
  start_link/0,
  send_message/1,
  delete_message/1,
  get_message/0
]).

%% gen_server callbacks
-export([
  init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3
]).

-define(SERVER, ?MODULE).
-define(MESSAGE_LIMIT, 100).

-record(state, {state :: atom(), queue :: queue, workers :: list(), limit :: integer()}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
  {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term()} | ignore).
init([]) ->
  {ok, #state{state = ready, queue = queue:new(), workers = [], limit = application:get_env(erlgram, limit, ?MESSAGE_LIMIT)}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #state{}) ->
  {reply, Reply :: term(), NewState :: #state{}} |
  {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
  {stop, Reason :: term(), NewState :: #state{}}).

handle_call(block, _From, State) ->
  {noreply, State#state{state = blocked}};

handle_call({new_message, Message}, _From, #state{queue = Queue0, limit = MessageLimit}=State) ->
  Queue = add_message_to_queue(Queue0, Message, MessageLimit),
  {reply, ok, State#state{state = ready, queue = Queue}};

handle_call(get_message, _From, #state{state = blocked}=State) ->
  {reply, {error, blocked}, State};

handle_call(get_message, {WorkerPid, _}, #state{queue = Queue, workers = Workers0}=State) ->

  Message = get_message_for_worker(Queue, Workers0),
  Workers = add_new_worker(Workers0, WorkerPid, Message),
  {reply, Message, State#state{workers = Workers, queue = Queue, state = ready}};

handle_call(_Request, _From, State) ->
  {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).

handle_cast({delete_message, Message}, #state{queue = Queue0, workers = Workers0}=State) ->

  Queue = delete_message_from_queue(Queue0, Message),
  Workers = delete_worker(Workers0, Message),
  {noreply, State#state{queue = Queue, state = ready, workers = Workers}};

handle_cast(_Request, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_info(Info, State) ->
  lager:log(info, [], "just got some info ~p~n", [Info]),
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).
terminate(_Reason, _State) ->
  lager:log(warning, [], "gen_server ~p is about to terminate, pid ~p~n", [?MODULE, self()]),
  ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
  {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%% send message to queue
-spec send_message(Message :: #message{}) -> ok.
send_message(Message) when is_record(Message, message) ->
  gen_server:call(?MODULE, {new_message, Message});

send_message(Message) ->
  lager:error("invalid message ~p~n", [Message]).

%% delete message from queue e.g. confirm process
-spec delete_message(Message :: #message{}) -> ok.
delete_message(Message) ->
  gen_server:cast(?MODULE, {delete_message, Message}).

%% get message from queue
-spec get_message() -> Message :: #message{} | tuple.
get_message() ->
  gen_server:call(?MODULE, get_message).


%%%===================================================================
%%% Helpers
%%%===================================================================

%% add new worker to gen_server state
-spec add_new_worker(list(), pid(), Message :: #message{} | tuple) -> list().
add_new_worker(Workers, WorkerPid, #message{id = MessageId}) ->
  [{MessageId, WorkerPid} | Workers];

add_new_worker(Workers, _WorkerPid, {error, empty_queue}) ->
  Workers.

%% add new element in the queue.
%% if limit reached we delete 1 replace 1st queue element with given
-spec add_message_to_queue(Queue :: queue, Message :: #message{}, integer()) -> Queue :: queue.
add_message_to_queue(Queue0, Message, Limit) ->
  QueueLen = queue:len(Queue0),

  if
    QueueLen >= Limit  ->
      {_, Queue} = queue:out(Queue0),
      queue:in_r(Message, Queue);

    true ->
      queue:in(Message, Queue0)
  end.

%% get message from queue which isn't in usage by any worker
-spec get_message_for_worker(Queue :: queue, list()) -> Value :: #message{}.
get_message_for_worker(Queue0, Workers) ->

  {Message, Queue} =
    try
      {{value, Message0}, Queue1} = queue:out(Queue0),
      {Message0, Queue1}
    catch
      Class:Error  ->
        lager:error("Module ~p Line ~p Class ~p Error ~p~n", [?MODULE, ?LINE, Class, Error]),
        {{error, empty_queue}, Queue0}
    end,

  %% if current message is in use by another worker, but unprocessed (exists in queue)
  %% get the next one
  if
    is_record(Message, message) ->
      case lists:keymember(Message#message.id, 1, Workers) of
        true ->
          get_message_for_worker(Queue, Workers);

        _ ->
          Message
      end;

    true ->
      Message
  end.

%% when message is processed we need to delete it from queue
-spec delete_message_from_queue(Queue :: queue, Message :: #message{}) -> Queue :: queue.
delete_message_from_queue(Queue, Message) ->
  F = fun(MessageFromQueue) -> Message =/= MessageFromQueue end,
  queue:filter(F, Queue).

%% when message is processed we need to delete worker from gen_server state
-spec delete_worker(list(), Message :: #message{}) -> list().
delete_worker(Workers, #message{id = MessageId}) ->
  lists:keydelete(MessageId, 1, Workers).



