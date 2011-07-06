#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "ei.h"
#include "erl_driver.h"
#include "erl_interface.h"

#include "redis.h"

#define REDIS_START 1
#define REDIS_STOP  0

typedef struct {
  ErlDrvPort port;
} redis_data;

void startRedisServer();
static ErlDrvBinary* ei_x_to_new_binary(const ei_x_buff *x_buff);

static ErlDrvData redis_drv_start(ErlDrvPort port, char *buff)
{
  redis_data* d = (redis_data*) driver_alloc(sizeof(redis_data));
  d->port = port;
  set_port_control_flags(port, PORT_CONTROL_FLAG_BINARY);
  
  // forking a process that is responsible to start a embedded
  // redis instance. I hope it's works.
  // pid_t pid = fork();
  // if(pid == 0) { // child
  //   startRedisServer();
  // }
  return (ErlDrvData) d;
}

static void redis_drv_stop(ErlDrvData handle)
{
  // stopRedisServer();
  driver_free((char*) handle);
}

// @deprecated! using redis_drv_control instead!
static void redis_drv_output(ErlDrvData handle, char *buff, int bufflen)
{
  redis_data* d = (redis_data*)handle;
  char fn = buff[0], arg = buff[1], res;

  printf("function %s\n", &fn);
  res = 2;
  driver_output(d->port, &res, 1);
}

static int redis_drv_control(ErlDrvData drv_data, unsigned int command, char *buf, int len, char **rbuf, int rlen)
{
  ei_x_buff x_buff; // this is le output?
  ei_x_new_with_version(&x_buff);

  switch(command) {
    case REDIS_START:
      start_redis_server();
      ei_x_encode_tuple_header(&x_buff, 2);
      ei_x_encode_atom(&x_buff, "ok");
      ei_x_encode_atom(&x_buff, "started");
      break;
    case REDIS_STOP:
      stop_redis_server();
      ei_x_encode_atom(&x_buff, "ok");
      break;
  }
  printf("function @redis_drv_control\n");
  *rbuf = (char*) ei_x_to_new_binary(&x_buff);
  ei_x_free(&x_buff);
  return 0;
}

static ErlDrvBinary* ei_x_to_new_binary(const ei_x_buff *x_buff)
{
  ErlDrvBinary *bin = driver_alloc_binary(x_buff->index);
  if(bin != NULL) {
    memcpy(bin->orig_bytes, x_buff->buff, x_buff->index);
  }
  return bin;
}

ErlDrvEntry redis_driver_entry = {
    NULL,			    /* F_PTR init, N/A */
    redis_drv_start,		    /* L_PTR start, called when port is opened */
    redis_drv_stop,		    /* F_PTR stop, called when port is closed */
    NULL,	    	            /* F_PTR output, called when erlang has sent */
    NULL,		            /* F_PTR ready_input, called when input descriptor ready */
    NULL,			    /* F_PTR ready_output, called when output descriptor ready */
    "redis_drv",	            /* char *driver_name, the argument to open_port */
    NULL,		            /* F_PTR finish, called when unloaded */
    redis_drv_control,              /* F_PTR control, port_command callback */
    NULL,			    /* F_PTR timeout, reserved */
    NULL  			    /* F_PTR outputv, reserved */
};

DRIVER_INIT(redis_drv)
{
  return &redis_driver_entry;
}

//
// Redis
//
void start_redis_server() {
  pid_t pid;
  pid = fork();
  if(pid == 0)
    boot_redis();
}

void boot_redis() {
  long long start;

  initServerConfig();
  
  if (server.daemonize) daemonize();
  initServer();
  if (server.daemonize) createPidFile();
  redisLog(REDIS_NOTICE,"Server started, Redis version " REDIS_VERSION);
#ifdef __linux__
  linuxOvercommitMemoryWarning();
#endif
  start = ustime();
  if (server.ds_enabled) {
    redisLog(REDIS_NOTICE,"DB not loaded (running with disk back end)");
  } else if (server.appendonly) {
    if (loadAppendOnlyFile(server.appendfilename) == REDIS_OK)
      redisLog(REDIS_NOTICE,"DB loaded from append only file: %.3f seconds",(float)(ustime()-start)/1000000);
    } else {
      if (rdbLoad(server.dbfilename) == REDIS_OK)
        redisLog(REDIS_NOTICE,"DB loaded from disk: %.3f seconds",(float)(ustime()-start)/1000000);
    }
  if (server.ipfd > 0)
    redisLog(REDIS_NOTICE,"The server is now ready to accept connections on port %d", server.port);
  if (server.sofd > 0)
    redisLog(REDIS_NOTICE,"The server is now ready to accept connections at %s", server.unixsocket);
  aeSetBeforeSleepProc(server.el,beforeSleep);
  aeMain(server.el);
  aeDeleteEventLoop(server.el);
}

void stop_redis_server() {
  prepareForShutdown();
}
