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

-define(JSX, jsx).
-define(JIFFY, jiffy).

%% API
-export([
  from_json/1,
  to_json/1
]).


from_json(JSON) ->
  from_json(?JIFFY, JSON).

from_json(?JIFFY, JSON) ->
  try
    jiffy:decode(JSON)
  catch
    _Class:_Error ->
      error
  end;

from_json(?JSX, JSON) ->
  try
    jsx:decode(JSON)
  catch
    _Class:_Error  ->
      error
  end.

to_json(Content) ->
  to_json(?JIFFY, Content).

to_json(?JIFFY, Content) ->
  try
    jiffy:encode(Content)
  catch
    _Class:_Error  ->
      error
  end;

to_json(?JSX, Content) ->
  try
    jsx:encode(Content)
  catch
    _Class:_Error->
      error
  end.

