-module(redis).
-compile(export_all).

-define(REDIS_START, 1).
-define(REDIS_STOP,  0).

% Erlang -> C     C -> Erlang
% start           ok | {error, Reason::atom()}
% stop            ok | {error, Reason::atom()}
% {set, X, Y}     ok | {error, Reason::atom()}
% {get, X}        {ok, Y} | {error, Reason:atom()}

setup(SharedLib) ->
  case erl_ddll:load_driver(".", SharedLib) of
    ok -> 
      ok;
    {error, already_loaded} ->
      ok;
    {error, ErrorDesc} ->
       exit(erl_ddll:format_error(ErrorDesc))
  end,
  register_lib(SharedLib).
%  spawn(?MODULE, init, [ SharedLib ]).
  
% init(SharedLib) ->
%  register(redis_driver, self()),
%  Port = open_port({spawn, SharedLib}, []),
%  loop(Port).

stop() ->
  [{port, Port}| _] = ets:lookup(redis_table, port),
  Port ! {close, self()},
  ok.
  
start_redis() ->
  binary_to_term(control(?REDIS_START, "")).

stop_redis() ->
  binary_to_term(control(?REDIS_STOP, "")).

%
% Internal
%
register_lib(SharedLib) ->
  Port = open_port({spawn, SharedLib}, []),
  Tab = ets:new(redis_table, [set, protected, named_table]),
  ets:insert(Tab, {port, Port}),
  Port.

control(Cmd, Data) ->
  [{port, Port}| _] = ets:lookup(redis_table, port),
  erlang:port_control(Port, Cmd, Data).

% call_port(Command) ->
%   redis_driver ! {call, self(), Command},
%   receive
%     {redis_driver, Result} ->
%       Result
%   end.

% loop(Port) ->
%   receive
%     {call, Caller, Msg} ->
%       Port ! {self(), {command, Msg}},
%       receive
%         {Port, {data, Data}} ->
%           Caller ! {redis_driver, Data}
%       end,
%       loop(Port);
%     stop ->
%       Port ! {self(), close},
%       receive
%         {Port, closed} ->
%           exit(normal)
%       end;
%     {'EXIT', Port, Reason} ->
%       io:format("~p ~n", [ Reason ]),
%       exit(port_terminated)
%   end.
