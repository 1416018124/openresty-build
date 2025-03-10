--[[
gitlab http 请求数限制逻辑 

Redis 的配置需要特别注意， 如果redis 连接不上默认跳过验证.
通过配置文件读取阈值

Author: Jiang Feng
Date: Mon Oct 21 04:52:21 PM CST 2024
Version: '0.0.2'
--]]
local util = require("util")
local _M = {}



--{"limit_type": "user", "limit_default_user":"anonymous","dry_run": false, "limit_args":[{"key": "cd_1517692165_118360", "rate":"2r/s","burst":0, "duration":0.5},{"key": "anonymous", "rate":"100r/s"}] }
local function get_user_config(reqlimitconf,user,limit_location)
    local default = {}
    for k,v in pairs(reqlimitconf.limit_args) do
        if user == v.key and  limit_location == v.limit_location then
            ngx.log(ngx.DEBUG, v.key .. ";"..v.rate..";".. v.burst.. ";"..v.duration)
            return v
        end
    end
    --public
    if user ~= "none" and reqlimitconf.limit_common_on then
        for k,v in ipairs(reqlimitconf.default_args) do
            if limit_location == v.limit_location then
                local public =  {key = user, rate = v.rate, burst = v.burst, default_conn_delay = v.default_conn_delay, dry_run = v.dry_run,limit_location=v.limit_location}
                return public
            end
        end
    else
        --default
        user = reqlimitconf.limit_default_user
        for k,v in pairs(reqlimitconf.limit_args) do
                --ngx.log(ngx.DEBUG, v.key .. ";".. v.rate..";".. v.burst.. ";"..v.duration .. ";" ..v.limit_location..";")
            if user == v.key and limit_location == v.limit_location then
                ngx.log(ngx.DEBUG, v.key .. ";".. v.rate..";".. v.burst.. ";"..v.duration)
                return v
            end
        end
    end
    return default
end

local function get_ip_config(reqlimitconf,user_ip,limit_location)
    local config = {}
    --判断IP是否在IP段内
    
    for k,v in ipairs(reqlimitconf.limit_args) do
        local ok = util.is_in_SubnetMask(user_ip, v.key)
        if ok and limit_location == v.limit_location then
            config = v
            --ngx.log(ngx.DEBUG,  "math key:" ..v.key.. v.rate..";".. v.burst.. ";"..v.default_conn_delay)
            return v
        end
    end
    --default 
    for k,v in ipairs(reqlimitconf.default_args) do
        if limit_location == v.limit_location then
            --ngx.log(ngx.DEBUG,  "default;".. v.rate..";".. v.burst.. ";"..v.default_conn_delay)
            return  {key = user_ip, rate = v.rate, burst = v.burst, default_conn_delay = v.default_conn_delay, dry_run = v.dry_run,limit_location = v.limit_location}
        end
    end
    return config
end

function _M.req_limit_logic(reqlimitconf,service)
    local user = ngx.var.remote_user or "none"
    local user_ip = ngx.var.remote_addr
    local limit_location = ngx.var.limit_location or "default"
    local req_limit = require("ratelimit")
    local args = {}
    if reqlimitconf.limit_type == "user" then
        args = get_user_config(reqlimitconf,user,limit_location)
    else
        args = get_ip_config(reqlimitconf,user_ip,limit_location)
    end
    if util.tableLength(args) == 0 then
        ngx.log(ngx.INFO, "this requesrt is not found reqlimit role match, client: ".. user_ip .. "; user:" .. user)
        return
    end

    local rate = args.rate
    local burst = args.burst
    local duration = args.duration
    local req_lim,err = req_limit.new("openresty",rate,burst,duration) 
    if not req_lim then
        ngx.log(ngx.ERR,
                "failed to instantiate a resty.limit.conn object: ", err)
        return
    end
    local key = service.. ":reqlimit:" .. args.key.. ":" .. args.limit_location
    local delay, err = req_lim:incoming(key, true)
    if not delay then
        if err == "rejected" then
            if reqlimitconf.dry_run == true then
                ngx.log(ngx.WARN, "{\"user\": \"".. user .. "\", \"client_address\": \"" .. user_ip .. "\",\"err\":\"trigger reqlimit\", \"try_run\"=true}")
            else
                ngx.log(ngx.ERR, "{\"user\": \"".. user .. "\", \"client_address\": \"" .. user_ip .. "\",\"err\":\"trigger reqlimit\"}")
                return ngx.exit(429)
            end
           
        end
        ngx.log(ngx.ERR, "failed to limit req: ", err)
        return
    end
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

