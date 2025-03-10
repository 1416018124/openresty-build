-- Copyright (C) Monkey Zhang (timebug), UPYUN Inc.

local type = type
local assert = assert
local floor = math.floor
local tonumber = tonumber
local iredis = require "redis_iresty"
local cjson = require("cjson")


local _M = {
    _VERSION = "0.03",

    BUSY = 2,
    FORBIDDEN = 3
}

local mt = {
    __index = _M
}

local is_str = function(s) return type(s) == "string" end
local is_num = function(n) return type(n) == "number" end

local function redis_commit(redis, zone, key, rate, burst, duration)
    local rate_num, burst_num = tonumber(rate), tonumber(burst)
    local now = ngx.now() * 1000
    local duration_num = tonumber(duration)
    key = zone .. ":" .. key
    local excess, last, forbidden = 0, 0, 0    
    local res = redis:get (key)
    if type(res) == "table" and res.err then
        return {err=res.err}
    end
    if res and type(res) == "string" then
        local v = cjson.decode(res)
        if v and #v > 2 then
            excess, last, forbidden = v[1], v[2], v[3]
        end
        if forbidden == 1 then
            return {3, excess} -- FORBIDDEN
        end
        local ms = math.abs(now - last)
        excess = excess - rate_num * ms / 1000 + 1000    
        if excess < 0 then
            excess = 0
        end
        if excess > 0 and excess < burst_num then
            ngx.log(ngx.WARN, "{err : \"this request is exceeding soft reqlimit,key: "..key .. "\"}")
        end
        if excess > burst_num then
            if duration_num > 0 then
                --ngx.log(ngx.ERR, "excess: "..excess .. ";burst_num:" .. burst_num)
                local res = redis:set(key,cjson.encode({excess, now, 1}))
                if type(res) == "table" and res.err then
                    return {err=res.err}
                end    
                local res = redis:expire(key, duration_num)
                if type(res) == "table" and res.err then
                    return {err=res.err}
                end
            end
    
            return {2, excess} -- BUSY
        end
    end
    local res = redis:set( key, cjson.encode({excess, now, 0}))
    if type(res) == "table" and res.err then
        return {err=res.err}
    end
    local res = redis:expire(key, 60)
    if type(res) == "table" and res.err then
        return {err=res.err}
    end
    return {1, excess}
end


-- local lim, err = class.new(zone, rate, burst, duration)
function _M.new(zone, rate, burst, duration)
    local zone = zone or "ratelimit"
    local rate = rate or "1r/s"
    local burst = burst or 0
    local duration = duration or 0

    local scale = 1
    local len = #rate

    if len > 3 and rate:sub(len - 2) == "r/s" then
        scale = 1
        rate = rate:sub(1, len - 3)
    elseif len > 3 and rate:sub(len - 2) == "r/m" then
        scale = 60
        rate = rate:sub(1, len - 3)
    end

    rate = tonumber(rate)

    assert(rate > 0 and burst >= 0 and duration >= 0)

    burst = burst * 1000
    rate = floor(rate * 1000 / scale)

    return setmetatable({
            zone = zone,
            rate = rate,
            burst = burst,
            duration = duration,
    }, mt)
end


-- lim:set_burst(burst)
function _M.set_burst(self, burst)
    assert(burst >= 0)

    self.burst = burst * 1000
end


-- local delay, err = lim:incoming(key, redis)
function _M.incoming(self, key, redis)
    if type(redis) ~= "table" then
        redis = {}
    end
    if not pcall(redis.get_reused_times, redis) then
        local red = iredis:new()
        if not red then
            return nil
        end
        redis = red
    end

    local res, err = redis_commit(
        redis, self.zone, key, self.rate, self.burst, self.duration)
    if not res then
        return nil, err
    end

    local state, excess = res[1], res[2]
    if state == _M.BUSY or state == _M.FORBIDDEN then
        return nil, "rejected"
    end

    -- state = _M.OK
    return excess / self.rate, excess / 1000
end


return _M
