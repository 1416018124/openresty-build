--[[
Copyright (C) Feng Jiang (15176921657@163.com)

This library is an enhanced Lua version of the standard ngx_limit_comn module
which writes data to Redis, Redis config is in redis_iresty
_VERSION = 0.0.3 connlimit参数封装成配置文件
Author: Jiang Feng
Date: Mon Oct 28 11:07:43 AM CST 2024
Reference link  https://github.com/openresty/lua-resty-limit-traffic/blob/master/lib/resty/limit/conn.md
--]]

local math = require "math"


local setmetatable = setmetatable
local floor = math.floor
local ngx_shared = ngx.shared
local assert = assert
local redis = require "redis_iresty"


local _M = {
    _VERSION = '0.01'
}


local mt = {
    __index = _M
}


function _M.new(max, burst, default_conn_delay)
    local red = redis:new()
    if not red then
        return nil, "redis conn error,please check redis_iresty"
    end

    assert(max > 0 and burst >= 0 and default_conn_delay > 0)

    local self = {
        redis = red,
        max = max + 0,    -- just to ensure the param is good
        burst = burst,
        unit_delay = default_conn_delay,
    }

    return setmetatable(self, mt)
end


function _M.incoming(self, key, commit)
    local redis = self.redis
    local max = self.max

    self.committed = false

    local conn, err
    if commit then
        conn, err = redis:incr(key)
        if not conn then
            return nil, err
        end
        if conn > max and conn < max + self.burst then
            ngx.log(ngx.WARN, "{err : \"this request is exceeding soft connlimit,key: "..key .. "\"}")
        end
        if conn > max + self.burst then
            conn, err = redis:decr(key)
            if not conn then
                return nil, err
            end
            return nil, "rejected"
        end
        self.committed = true

    else
        conn = (redis:get(key) or 0) + 1
        if conn > max + self.burst then
            return nil, "rejected"
        end
    end

    if conn > max then
        -- make the excessive connections wait
        return self.unit_delay * floor((conn - 1) / max), conn
    end

    -- we return a 0 delay by default
    return 0, conn
end


function _M.is_committed(self)
    return self.committed
end


function _M.leaving(self, key, req_latency)
    assert(key)
    local redis = self.redis

    local conn, err = redis:decr(key)
    if not conn then
        return nil, err
    end

    if req_latency then
        local unit_delay = self.unit_delay
        self.unit_delay = (req_latency + unit_delay) / 2
    end
    if conn == 0 then
        local ok,err = redis:expire(key, 60)
        if not ok then
            ngx.log(ngx.ERR, "failed to set expire time: ", err)
            return nil
        end
    end

    return conn
end


function _M.uncommit(self, key)
    assert(key)
    local redis = self.redis

    return redis:incr(key)
end


function _M.set_conn(self, conn)
    self.max = conn
end


function _M.set_burst(self, burst)
    self.burst = burst
end


return _M
