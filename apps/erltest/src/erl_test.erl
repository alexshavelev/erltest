%%%-------------------------------------------------------------------
%%% @author alex_shavelev
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Apr 2016 12:40
%%%-------------------------------------------------------------------
-module(erl_test).
-author("alex_shavelev").

%% API
-export([test/0, test/1, t/0]).

t() ->
%%  Dispatch = cowboy_router:compile([{'_', [
%%
%%
%%
%%
%%    % site router
%%    {"/[...]", http_site_handler, []}
%%  ]}]),
%%
%%  ProtoOpts = [
%%    {env, [{dispatch, Dispatch}]},
%%    {max_keepalive, 15000}
%%  ],
%%  TransOpts = [{max_connections, 100000}],
%%
%%  Acceptors   = 100,

  Dispatch = cowboy_router:compile([
    {'_', [{"/", hello_hanler, []}]}
  ]),

  Port = 8000,
  {ok, _HttpPid} =
    cowboy:start_http(my_http_listener, 100, [{port, 8080}],
      [{env, [{dispatch, Dispatch}]}]
    ),
  lager:info("HTTP listener started on port ~p", [Port]).


test(Path) ->
  Path1 = " \"" ++ binary_to_list(Path) ++ "\"",

  CommandPre =
    [
      "ffprobe -v error -show_entries stream=width,height -of default=noprint_wrappers=1",
      Path1
    ],

  Command = string:join(CommandPre, " "),

  Port = open_port({spawn, Command}, [stderr_to_stdout, exit_status, {line, 150}]),
  receive_all(Port).


test() ->
  io:format("LINE ~p~n", [?LINE]),

  Path = <<"/inStudio Library/Buffers/Local inStudio Buffer/2004/01-styczen/09/1404 Jan Kowalski 1404 test basketball111.mov">>,
  test(Path).


-spec receive_all(port()) -> {integer(), [string()]} | cancel.
receive_all(Port) ->
  receive_all(Port, []).

-spec receive_all(port(), [string()]) -> {integer(), [string()]} | cancel.
receive_all(Port, Acc) ->
  receive
    {Port, {data, X}} ->
      receive_all(Port, [X|Acc]);
    {Port, {exit_status, N}} ->
      {N, lists:reverse(Acc)};
    cancel ->
      cancel
  end.
