--[[
gitlab http 连接数限制逻辑 

Redis 的配置需要特别注意， 如果redis 连接不上默认跳过验证.
通过配置文件读取阈值

Author: Jiang Feng
Date: Mon Oct 21 04:52:21 PM CST 2024
Version: '0.0.2'
--]]
local util = require("util")
local limit_conn = require("connlimit")
local _M = {}


-- limit the requests under 200 concurrent requests (normally just
-- incoming connections unless protocols like SPDY is used) with
-- a burst of 100 extra concurrent requests, that is, we delay
-- requests under 300 concurrent connections and above 200
-- connections, and reject any new requests exceeding 300
-- connections.
-- also, we assume a default request time of 0.5 sec, which can be
-- dynamically adjusted by the leaving() call in log_by_lua below.
-- 将请求限制在200个并发请求以下（通常仅
-- 传入连接，除非使用SPDY等协议）
-- 100个额外并发请求的突发，即我们延迟
-- 300个并发连接以下和200个以上的请求
-- 连接，并拒绝任何超过300的新请求
-- 连接。
-- 此外，我们假设默认请求时间为0.5秒，可以是
-- 通过下面logbylua中的leaving（）调用动态调整。

local function get_user_config(connlimitconf,user,limit_location)
    local default = {}
    for k,v in ipairs(connlimitconf.limit_args) do
        if user == v.key and limit_location == v.limit_location then
            return v
        end
    end
    --public
    if user ~= "none" and connlimitconf.limit_common_on then
        for k,v in ipairs(connlimitconf.default_args) do
            if limit_location == v.limit_location then
                --ngx.log(ngx.DEBUG, "public;"..v.max..";".. v.burst.. ";"..v.default_conn_delay)
                local public =  {key = user, max = v.max, burst = v.burst, default_conn_delay = v.default_conn_delay, dry_run = v.dry_run,limit_location=v.limit_location}
                return public
            end
        end
    else
        --default
        user = connlimitconf.limit_default_user
        for k,v in ipairs(connlimitconf.limit_args) do
            --ngx.log(ngx.DEBUG, "default;"..v.max..";".. v.burst.. ";"..v.default_conn_delay..";"..v.limit_location..";")
            if user == v.key and limit_location == v.limit_location then
                ngx.log(ngx.DEBUG, v.key .. ";".. v.max..";".. v.burst.. ";"..v.default_conn_delay)

                return v
            end
        end
    end
    return nil
end

local function get_ip_config(connlimitconf,user_ip,limit_location)
    local util = require("util")
    local config = {}
    --判断IP是否在IP断内
    for k,v in ipairs(connlimitconf.limit_args) do
        local ok = util.is_in_SubnetMask(user_ip, v.key)
        if ok and limit_location == v.limit_location then
            config = v
            --ngx.log(ngx.DEBUG,  "math key:" ..v.key.. v.max..";".. v.burst.. ";"..v.default_conn_delay)
            return config
        end
    end
    --default 
    for k,v in ipairs(connlimitconf.default_args) do
        if limit_location == v.limit_location then
            --ngx.log(ngx.DEBUG,  "default;".. v.max..";".. v.burst.. ";"..v.default_conn_delay)
            return  {key = user_ip, max = v.max, burst = v.burst, default_conn_delay = v.default_conn_delay, dry_run = v.dry_run,limit_location = v.limit_location}
        end
    end
    return config
end

function _M.conn_limit_logic(connlimitconf,service)
    ngx.log(ngx.DEBUG, service.." conn limit is start")
    local user = ngx.var.remote_user or "none"
    ngx.log(ngx.DEBUG, "user:"..user)
    local user_ip = ngx.var.remote_addr
    ngx.log(ngx.DEBUG, "user_ip:"..user_ip)
    local limit_location = ngx.var.limit_location or ""
    ngx.log(ngx.DEBUG, "limit_location:"..limit_location..";")

    local args = {}
    if connlimitconf.limit_type == "user" then
        args = get_user_config(connlimitconf,user,limit_location)
    else
        args = get_ip_config(connlimitconf,user_ip,limit_location)
    end

    if util.tableLength(args) == 0 then
        ngx.log(ngx.INFO, "this requesrt is not found connlimit role match, client: ".. user_ip .. "; user:" .. user)
        return
    end

    local max = args.max
    local burst = args.burst
    local default_conn_delay = args.default_conn_delay
    local dry_run = args.dry_run
    local conn_lim,err = limit_conn.new(max,burst,default_conn_delay) 
    if not conn_lim then
        ngx.log(ngx.ERR,
                "failed to instantiate a resty.limit.conn object: ", err)
        return
    end
    local key = "openresty:" .. service.. ":connlimit:" .. args.key .. ":" .. args.limit_location
    ngx.log(ngx.DEBUG, "redis key:" .. key)
    local delay, err = conn_lim:incoming(key, true)
    if not delay then
        if err == "rejected" then
            if dry_run == true then
                ngx.log(ngx.WARN, "{\"user\": \"".. user .. "\", \"client_address\": \"" .. user_ip .. "\",\"err\":\"trigger connlimit\", \"try_run\"=true}")
            else
                ngx.log(ngx.ERR, "{\"user\": \"".. user .. "\", \"client_address\": \"" .. user_ip .. "\",\"err\":\"trigger connlimit\"}")
                return ngx.exit(429)
            end
           
        end
        ngx.log(ngx.ERR, "failed to limit req: ", err)
        return
    end
    
    if conn_lim:is_committed() then
        local ctx = ngx.ctx
        ctx.limit_conn = conn_lim
        ctx.limit_conn_key = key
        ctx.limit_conn_delay = delay
    end
    
    -- the 2nd return value holds the current concurrency level
    -- for the specified key.
    local conn = err
    
    if delay >= 0.001 then
        -- the request exceeding the 200 connections ratio but below
        -- 300 connections, so
        -- we intentionally delay it here a bit to conform to the
        -- 200 connection limit.
        -- ngx.log(ngx.WARN, "delaying")
        ngx.sleep(delay)
    end
end


return _M
