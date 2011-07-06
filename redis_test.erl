-module(redis_test).
-compile(export_all).

-define(REDIS_DRV, "redis_drv").

setup() ->
  redis:setup(?REDIS_DRV).

start() -> 
  setup(),
  redis:call_port(redis_command:start()).

stop()  ->
  setup(),
  redis:call_port(redis_command:stop()).
