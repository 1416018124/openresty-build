local _M = {}

function _M.ip_rule(service)
    -- 获取客户端IP和请求路径
    local client_ip = ngx.var.remote_addr

    -- Redis相关配置
    local redis_key_black_list = "openresty:".. service ..":black_list"
    local redis_key_white_list = "openresty:".. service ..":white_list"

    local redis = require "redis_iresty"
    local red = redis:new()
    -- 检查IP是否在黑名单中
    local is_in_blacklist, err = red:sismember(redis_key_black_list, client_ip)
    if is_in_blacklist == 1 then
        --检查IP是否在白名单中
        local is_in_whitelist, err = red:sismember(redis_key_white_list, client_ip)
        if is_in_whitelist == 1 then
            -- ngx.say("Access Denied")
            -- ngx.exit(403)
            return false
        end
        return true
    end
    return false
end

return _M
