--[[
Copyright (C) Feng Jiang (15176921657@163.com)

redis 封装脚本
_VERSION = 0.0.2 目前根据业务需求，增加了认证部分的功能和 连接哨兵的功能
_VERSION = 0.0.3 redis连接封装成配置文件

Author: Jiang Feng
Date: Mon Oct 28 11:07:43 AM CST 2024
Reference link https://moonbingbing.gitbooks.io/openresty-best-practices/content/redis/out_package.html
--]]
local redis_c = require "resty.redis"
local get_conf = require("get_conf")
local redisconf = get_conf.get_defaultConf("default").redis
local passwd = redisconf.password or nil



local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end


local _M = new_tab(0, 155)
_M._VERSION = '0.03'


local commands = {
    "append",            "auth",              "bgrewriteaof",
    "bgsave",            "bitcount",          "bitop",
    "blpop",             "brpop",
    "brpoplpush",        "client",            "config",
    "dbsize",
    "debug",             "decr",              "decrby",
    "del",               "discard",           "dump",
    "echo",
    "eval",              "exec",              "exists",
    "expire",            "expireat",          "flushall",
    "flushdb",           "get",               "getbit",
    "getrange",          "getset",            "hdel",
    "hexists",           "hget",              "hgetall",
    "hincrby",           "hincrbyfloat",      "hkeys",
    "hlen",
    "hmget",              "hmset",      "hscan",
    "hset",
    "hsetnx",            "hvals",             "incr",
    "incrby",            "incrbyfloat",       "info",
    "keys",
    "lastsave",          "lindex",            "linsert",
    "llen",              "lpop",              "lpush",
    "lpushx",            "lrange",            "lrem",
    "lset",              "ltrim",             "mget",
    "migrate",
    "monitor",           "move",              "mset",
    "msetnx",            "multi",             "object",
    "persist",           "pexpire",           "pexpireat",
    "ping",              "psetex",            "psubscribe",
    "pttl",
    "publish",      --[[ "punsubscribe", ]]   "pubsub",
    "quit",
    "randomkey",         "rename",            "renamenx",
    "restore",
    "rpop",              "rpoplpush",         "rpush",
    "rpushx",            "sadd",              "save",
    "scan",              "scard",             "script",
    "sdiff",             "sdiffstore",
    "select",            "set",               "setbit",
    "setex",             "setnx",             "setrange",
    "shutdown",          "sinter",            "sinterstore",
    "sismember",         "slaveof",           "slowlog",
    "smembers",          "smove",             "sort",
    "spop",              "srandmember",       "srem",
    "sscan",
    "strlen",       --[[ "subscribe",  ]]     "sunion",
    "sunionstore",       "sync",              "time",
    "ttl",
    "type",         --[[ "unsubscribe", ]]    "unwatch",
    "watch",             "zadd",              "zcard",
    "zcount",            "zincrby",           "zinterstore",
    "zrange",            "zrangebyscore",     "zrank",
    "zrem",              "zremrangebyrank",   "zremrangebyscore",
    "zrevrange",         "zrevrangebyscore",  "zrevrank",
    "zscan",
    "zscore",            "zunionstore",       "evalsha"
}


local mt = { __index = _M }


local function is_redis_null( res )
    if type(res) == "table" then
        for k,v in pairs(res) do
            if v ~= ngx.null then
                return false
            end
        end
        return true
    elseif res == ngx.null then
        return true
    elseif res == nil then
        return true
    end

    return false
end


function _M.connect_mod( self, redis )
    redis:set_timeout(self.timeout)
    local redis_s, err = redis_c:new()
    if redisconf.type == "sentinel" then
        for _, sentinel in ipairs(redisconf.hosts) do
            local ok, err = redis_s:connect(sentinel.host, sentinel.port)
            if ok then
                local res, err = redis_s:sentinel("get-master-addr-by-name", redisconf.sentinel_name)
                if res then
                    --return res[1], res[2]  -- 主节点的 host 和 port
                    return redis:connect(res[1], res[2] )
                end
                else 
                    ngx.log(ngx.ERR, err)
            end
        end
    else
        --ngx.log(ngx.DEBUG, "redis is solo")
        for _, host in ipairs(redisconf.hosts) do
            --ngx.log(ngx.DEBUG, host.host)
            return redis:connect(host.host, host.port )
        end
    end
end

function _M.set_keepalive_mod( redis )
    -- put it into the connection pool of size 100, with 60 seconds max idle time
    return redis:set_keepalive(60000, 1000)
end


function _M.init_pipeline( self )
    self._reqs = {}
end


function _M.commit_pipeline( self )
    local reqs = self._reqs

    if nil == reqs or 0 == #reqs then
        return {}, "no pipeline"
    else
        self._reqs = nil
    end

    local redis, err = redis_c:new()
    if not redis then
        return nil, err
    end

    local ok, err = self:connect_mod(redis)
    if not ok then
        return {}, err
    end
    -- local count
    -- count, err = redis:get_reused_times()
    -- if 0 == count then
    --     ok, err = redis:auth(redisconf.password)
    --     if not ok then
    --         ngx.log(ngx.ERR,"failed to auth: ", err)
    --         return
    --     end
    -- elseif err then
    --     ngx.log(ngx.ERR,"failed to get reused times: ", err)
    --     return
    -- end
    if passwd ~= nil then
        ok, err = red:auth(passwd)
        if not ok then
            ngx.log(ngx.ERR,"failed to auth: ", err)
            return
        end
    end

    redis:init_pipeline()
    for _, vals in ipairs(reqs) do
        local fun = redis[vals[1]]
        table.remove(vals , 1)

        fun(redis, unpack(vals))
    end

    local results, err = redis:commit_pipeline()
    if not results or err then
        return {}, err
    end

    if is_redis_null(results) then
        results = {}
        ngx.log(ngx.WARN, "is null")
    end
    -- table.remove (results , 1)

    self.set_keepalive_mod(redis)

    for i,value in ipairs(results) do
        if is_redis_null(value) then
            results[i] = nil
        end
    end

    return results, err
end


function _M.subscribe( self, channel )
    local redis, err = redis_c:new()
    if not redis then
        return nil, err
    end

    local ok, err = self:connect_mod(redis)
    if not ok or err then
        return nil, err
    end
    --local count
    --count, err = red:get_reused_times()
    --if 0 == count then
    --    ok, err = red:auth(passwd)
    --    if not ok then
    --        ngx.log(ngx.ERR,"failed to auth: ", err)
    --        return
    --    end
    --elseif err then
    --    ngx.log(ngx.ERR,"failed to get reused times: ", err)
    --    return
    --end
    if passwd ~= nil then
        ok, err = red:auth(passwd)
        if not ok then
            ngx.log(ngx.ERR,"failed to auth: ", err)
            return
        end
    end

    local res, err = redis:subscribe(channel)
    if not res then
        return nil, err
    end

    res, err = redis:read_reply()
    if not res then
        return nil, err
    end

    redis:unsubscribe(channel)
    self.set_keepalive_mod(redis)

    return res, err
end


local function do_command(self, cmd, ... )
    if self._reqs then
        table.insert(self._reqs, {cmd, ...})
        return
    end

    local redis, err = redis_c:new()
    if not redis then
        return nil, err
    end

    local ok, err = self:connect_mod(redis)
    if not ok or err then
        return nil, err
    end
    --local count
    --count, err = redis:get_reused_times()
    --if 0 == count then
    --    ok, err = redis:auth(redisconf.password)
    --    if not ok then
    --        ngx.log(ngx.ERR,"do_command failed to auth: ", err)
    --        return
    --    end
    --elseif err then
    --    ngx.log(ngx.ERR,"failed to get reused times: ", err)
    --    return
    --end
    if passwd ~= nil then
        ok, err = red:auth(passwd)
        if not ok then
            ngx.log(ngx.ERR,"failed to auth: ", err)
            return
        end
    end

    local fun = redis[cmd]
    local result, err = fun(redis, ...)
    if not result or err then
        ngx.log(ngx.ERR, "pipeline result:", result, " err:", err)
        return nil, err
    end

    if is_redis_null(result) then
        result = nil
    end

    self.set_keepalive_mod(redis)

    return result, err
end


for i = 1, #commands do
    local cmd = commands[i]
    _M[cmd] =
            function (self, ...)
                return do_command(self, cmd, ...)
            end
end


function _M.new(self, opts)
    opts = opts or {}
    local timeout = (opts.timeout and opts.timeout * 1000) or 1000
    local db_index= opts.db_index or 0

    return setmetatable({
            timeout = timeout,
            db_index = db_index,
            _reqs = nil }, mt)
end


return _M
