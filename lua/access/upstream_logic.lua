local redis = require "resty.redis_iresty"
local _M = {}

function _M.upstream_logic(healthcheckTable, service)
    local available_host = {}
    for k,v in ipairs (healthcheckTable.target) do
        local red = redis:new()
        local key = "openresty:healthcheckupstream:"..v.host..":"..v.port
        -- ngx.log(ngx.DEBUG, key)
        local value,err = red:get(key)
        if value == "healthy" then
            -- ngx.log(ngx.ERR, v.host)
            table.insert(available_host, {host=v.host, port=v.port})
        end
    end
    if healthcheckTable.load_balance == "first" then
        for k,v in pairs(available_host) do
            ngx.var.upstream_address = v.host..":"..v.port
            return
        end
    else
        math.randomseed(os.time())
        -- 生成随机整数
        local random_number = math.floor(math.random() * #available_host +1)
        for k,v in pairs(available_host) do
            if k == random_number then
                ngx.var.upstream_address = v.host..":"..v.port
            return
            end
        end
    end
    local default_host = healthcheckTable.target[1].host .. ":" .. healthcheckTable.target[1].port
    ngx.log(ngx.DEBUG, "use default")
    ngx.var.upstream_address = default_host
end

return _M


