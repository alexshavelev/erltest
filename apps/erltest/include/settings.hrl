%%%-------------------------------------------------------------------
%%% @author alex_shavelev
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Apr 2016 20:26
%%%-------------------------------------------------------------------
-author("alex_shavelev").

-define( IsA( Data ), is_atom( Data ) ).
-define( IsB( Data ), is_binary( Data ) ).
-define( IsI( Data ), is_integer( Data ) ).
-define( IsF( Data ), is_float( Data ) ).
-define( IsL( Data ), is_list( Data ) ).
-define( IsT( Data ), is_tuple( Data ) ).
-define( A2B( Data ), ?L2B( ?A2L( Data ) ) ).
-define( I2B( Data ), ?L2B( ?I2L( Data ) ) ).
-define( L2B( Data ), list_to_binary( Data ) ).
-define( F2B( Data ), float_to_binary( Data ) ).
-define( I2L( Data ), integer_to_list( Data ) ).
-define( A2L( Data ), atom_to_list( Data ) ).