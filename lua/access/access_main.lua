--[[
http 请求 access_by_lua 入口函数

在这里根据域名的lua.json,判断需要的功能，然后按需执行

Author: Jiang Feng
Date: Mon Sep 30 11:17:38 AM CST 2024

--]]
local get_conf = require("get_conf")
local function main()
    --对于没有配置lua.conf的请求，默认跳过
    if get_conf.get_domainconf(ngx.var.host) == nil then
        return
    end
    local basic = get_conf.app("basic")
    local service = basic.service
    if basic.ip_deny == true then
        -- IP黑白名单
        local ip_deny = require("ip_deny")
        local res = ip_deny.ip_rule(service)
        if res then
            local user = ngx.var.remote_user or "none"
            local user_ip = ngx.var.remote_addr
            ngx.log(ngx.ERR, "{\"user\": \"".. user .. "\", \"client_address\": \"" .. user_ip .. "\",\"err\":\"ip_deny\"}")

            ngx.exit(403)
        end

   end
   local reqlimitTable = get_conf.app("reqlimit")
   if  reqlimitTable then
        -- 执行request limit
        local reqlimit = require("reqlimit_logic")
        reqlimit.req_limit_logic(reqlimitTable,service)
   end

   local connlimitTable = get_conf.app("connlimit")

   if connlimitTable then
        -- 执行connnect limit
        local connlimit = require("connlimit_logic")
        connlimit.conn_limit_logic(connlimitTable,service)
   end
end

main()

