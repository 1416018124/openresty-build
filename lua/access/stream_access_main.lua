--[[
stream 请求 proread_by_lua 入口函数

在这里根据域名的lua.json,判断需要的功能，然后按需执行

Author: Jiang Feng
Date: 2024年 10月 31日 星期四 09:35:27 CST
--]]
local get_conf = require("get_conf")
local function main()
    --对于没有配置lua.conf的请求，默认跳过
    -- ngx.log(ngx.ERR,ngx.var.host)
    if get_conf.get_domainconf(ngx.var.host) == nil then
        return
    end
    local basic = get_conf.get_conf("basic")
    local service = basic.service
    if basic.ip_deny == true then
        -- IP黑白名单
        local ip_deny = require("ip_deny")
        local res = ip_deny.ip_rule(service)
        if res then
            ngx.log(ngx.INFO, "Access Deny")
            ngx.exit(403)
        end

    end
    local reqlimitTable = get_conf.get_reqlimit()
    if  reqlimitTable and reqlimitTable.reqlimit_on then
        -- 执行request limit
        local reqlimit = require("reqlimit_logic")
        reqlimit.req_limit_logic(reqlimitTable,service)
    end

    local connlimitTable = get_conf.get_connlimit()
    if connlimitTable and connlimitTable.connlimit_on then
        -- 执行connnect limit
        local connlimit = require("connlimit_logic")
        connlimit.conn_limit_logic(connlimitTable,service)
    end
    local healthcheckTable = get_conf.get_domain_healthcheck(ngx.var.host)
    if healthcheckTable and healthcheckTable.health_on then

    -- 执行upstream操作
        local upstream = require("upstream_logic")
        upstream.upstream_logic(healthcheckTable,service)
    end
end

main()

