-module(erltest_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    Dispatch = cowboy_router:compile([
        {'_', [{"/", hello_hanler, []}]}
    ]),

    {ok, _} = cowboy:start_http(my_http_listener, 100, [{port, 6634}],
        [{env, [{dispatch, Dispatch}]}]
    ),

    erltest_sup:start_link().

stop(_State) ->
    ok.
