INSTALL := /root/openresty-build/sources/openresty-1.27.1.1/build/install

.PHONY: all install clean

all:
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/LuaJIT-2.1-20240815 && $(MAKE) TARGET_STRIP=@: CCDEBUG=-g XCFLAGS='-DLUAJIT_ENABLE_LUA52COMPAT' CC=cc PREFIX=/usr/local/openresty/luajit
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-cjson-2.1.0.14 && $(MAKE) DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/openresty-build/sources/openresty-1.27.1.1/build/luajit-root/usr/local/openresty/luajit/include/luajit-2.1 LUA_CMODULE_DIR=/usr/local/openresty/lualib LUA_MODULE_DIR=/usr/local/openresty/lualib CJSON_CFLAGS="-g -fpic" CC=cc
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-signal-0.04 && $(MAKE) DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/openresty-build/sources/openresty-1.27.1.1/build/luajit-root/usr/local/openresty/luajit/include/luajit-2.1 LUA_LIB_DIR=/usr/local/openresty/lualib CC=cc
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-redis-parser-0.13 && $(MAKE) DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/openresty-build/sources/openresty-1.27.1.1/build/luajit-root/usr/local/openresty/luajit/include/luajit-2.1 LUA_LIB_DIR=/usr/local/openresty/lualib CC=cc
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-rds-parser-0.06 && $(MAKE) DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/openresty-build/sources/openresty-1.27.1.1/build/luajit-root/usr/local/openresty/luajit/include/luajit-2.1 LUA_LIB_DIR=/usr/local/openresty/lualib CC=cc
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/nginx-1.27.1 && $(MAKE)

install: all
	mkdir -p $(DESTDIR)/usr/local/openresty/
	-cp /root/openresty-build/sources/openresty-1.27.1.1/COPYRIGHT $(DESTDIR)/usr/local/openresty/
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/LuaJIT-2.1-20240815 && $(MAKE) install TARGET_STRIP=@: CCDEBUG=-g XCFLAGS='-DLUAJIT_ENABLE_LUA52COMPAT' CC=cc PREFIX=/usr/local/openresty/luajit DESTDIR=$(DESTDIR)
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-cjson-2.1.0.14 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/openresty-build/sources/openresty-1.27.1.1/build/luajit-root/usr/local/openresty/luajit/include/luajit-2.1 LUA_CMODULE_DIR=/usr/local/openresty/lualib LUA_MODULE_DIR=/usr/local/openresty/lualib CJSON_CFLAGS="-g -fpic" CC=cc
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-signal-0.04 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/openresty-build/sources/openresty-1.27.1.1/build/luajit-root/usr/local/openresty/luajit/include/luajit-2.1 LUA_LIB_DIR=/usr/local/openresty/lualib CC=cc
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-redis-parser-0.13 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/openresty-build/sources/openresty-1.27.1.1/build/luajit-root/usr/local/openresty/luajit/include/luajit-2.1 LUA_LIB_DIR=/usr/local/openresty/lualib CC=cc
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-rds-parser-0.06 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/openresty-build/sources/openresty-1.27.1.1/build/luajit-root/usr/local/openresty/luajit/include/luajit-2.1 LUA_LIB_DIR=/usr/local/openresty/lualib CC=cc
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-dns-0.23 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-memcached-0.17 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-redis-0.31 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-mysql-0.27 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-string-0.16 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-upload-0.11 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-websocket-0.12 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-lock-0.09 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-lrucache-0.15 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-core-0.1.30 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-upstream-healthcheck-0.08 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-limit-traffic-0.09 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-resty-shell-0.03 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/lua-tablepool-0.03 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/usr/local/openresty/lualib INSTALL='$(INSTALL)'
	mkdir -p '$(DESTDIR)/usr/local/openresty/bin/'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/opm-0.0.8 && $(INSTALL) bin/* '$(DESTDIR)/usr/local/openresty/bin/'
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/resty-cli-0.30 && $(INSTALL) bin/* $(DESTDIR)/usr/local/openresty/bin/
	cp /root/openresty-build/sources/openresty-1.27.1.1/build/resty.index $(DESTDIR)/usr/local/openresty/
	cp -r /root/openresty-build/sources/openresty-1.27.1.1/build/pod $(DESTDIR)/usr/local/openresty/
	cd /root/openresty-build/sources/openresty-1.27.1.1/build/nginx-1.27.1 && $(MAKE) install DESTDIR=$(DESTDIR)
	mkdir -p $(DESTDIR)/usr/local/openresty/site/lualib $(DESTDIR)/usr/local/openresty/site/pod $(DESTDIR)/usr/local/openresty/site/manifest
	ln -sf /usr/local/openresty/nginx/sbin/nginx $(DESTDIR)/usr/local/openresty/bin/openresty

clean:
	rm -rf build *.exe *.dll openresty-*
