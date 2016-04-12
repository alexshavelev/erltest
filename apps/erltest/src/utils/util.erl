%%%-------------------------------------------------------------------
%%% @author alex_shavelev
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Apr 2016 16:04
%%%-------------------------------------------------------------------
-module(util).
-author("alex_shavelev").

-include("settings.hrl").

-define(JSX, jsx).
-define(JIFFY, jiffy).

%% API
-export([
  get_random_id/0,
  to_binary/1
]).

-spec get_random_id() -> integer().
get_random_id() ->
  {Mega, Secs, MicroSecs} = erlang:now(),
  Timestamp = Mega*1000000 + Secs + MicroSecs,
  Timestamp.

to_binary( Value ) when ?IsB( Value ) -> Value;
to_binary( Value ) when ?IsI( Value ) -> ?I2B( Value );
to_binary( Value ) when ?IsL( Value ) -> ?L2B( Value );
to_binary( Value ) when ?IsA( Value ) -> ?A2B( Value ).

