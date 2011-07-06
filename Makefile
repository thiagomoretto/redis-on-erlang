ERLANG_INSTALL=/opt/local
ERTS_PATH=$(ERLANG_INSTALL)/lib/erlang/erts-5.8.2
ERL_INTERFACE_PATH=$(ERLANG_INSTALL)/lib/erlang/lib/erl_interface-3.7.2

REDIS_SRC_PATH=redis/src/
# Uhh! Soooo ugly!
REDIS_OBJS=$(REDIS_SRC_PATH)adlist.o $(REDIS_SRC_PATH)ae.o $(REDIS_SRC_PATH)anet.o $(REDIS_SRC_PATH)dict.o $(REDIS_SRC_PATH)redis.o $(REDIS_SRC_PATH)sds.o $(REDIS_SRC_PATH)zmalloc.o $(REDIS_SRC_PATH)lzf_c.o $(REDIS_SRC_PATH)lzf_d.o $(REDIS_SRC_PATH)pqsort.o $(REDIS_SRC_PATH)zipmap.o $(REDIS_SRC_PATH)sha1.o $(REDIS_SRC_PATH)ziplist.o $(REDIS_SRC_PATH)release.o $(REDIS_SRC_PATH)networking.o $(REDIS_SRC_PATH)util.o $(REDIS_SRC_PATH)object.o $(REDIS_SRC_PATH)db.o $(REDIS_SRC_PATH)replication.o $(REDIS_SRC_PATH)rdb.o $(REDIS_SRC_PATH)t_string.o $(REDIS_SRC_PATH)t_list.o $(REDIS_SRC_PATH)t_set.o $(REDIS_SRC_PATH)t_zset.o $(REDIS_SRC_PATH)t_hash.o $(REDIS_SRC_PATH)config.o $(REDIS_SRC_PATH)aof.o $(REDIS_SRC_PATH)dscache.o $(REDIS_SRC_PATH)pubsub.o $(REDIS_SRC_PATH)multi.o $(REDIS_SRC_PATH)debug.o $(REDIS_SRC_PATH)sort.o $(REDIS_SRC_PATH)intset.o $(REDIS_SRC_PATH)syncio.o $(REDIS_SRC_PATH)diskstore.o

CC=gcc 
CFLAGS=-undefined suppress -flat_namespace \
       	-L$(ERTS_PATH)/lib/ -L$(ERL_INTERFACE_PATH)/lib/ \
	-I$(ERTS_PATH)/include/ -I$(ERL_INTERFACE_PATH)/include/ \
	-I$(REDIS_SRC_PATH) \
  	-fpic -O2

default: redis_drv.so

redis_drv.o: redis_drv.c

redis.o: 
	cd $(REDIS_SRC_PATH) && $(MAKE) all

.o.c:
	$(CC) $(CFLAGS)

redis_drv.so: redis_drv.o
	$(CC) -o redis_drv.so -undefined suppress -flat_namespace \
  	-L$(ERTS_PATH)/lib/ -L$(ERL_INTERFACE_PATH)/lib/ \
  	-I$(ERTS_PATH)/include/ -I$(ERL_INTERFACE_PATH)/include/ \
	-lei -lerl_interface \
  	-shared redis_drv.o $(REDIS_OBJS) 

clean:
	rm -rf *.o *.out *.so
