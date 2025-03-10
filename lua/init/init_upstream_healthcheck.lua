local we = require "resty.worker.events"
local healthcheck = require "resty.healthcheck"
local redis = require "redis_iresty"
local conf = ngx.shared.conf
local get_conf = require("get_conf")
local healthcheckconftable = get_conf.get_defaultConf("healthcheck")
local checker = {}

local _M = {}



local function redis_healthcheck_change(premature, key, value)
    if premature then
        return
    end
    ngx.log(ngx.DEBUG, "Timer callback with args: ", key, " and ", value)
    local red = redis:new()
    red:set(key,value)
end

local function event_handler(target, eventname, sourcename, pid)
    if eventname == checker.events.remove then
        -- a target was removed
        ngx.log(ngx.ERR,"Target removed: ",
            target.ip, ":", target.port, " ", target.hostname)
    elseif eventname == checker.events.healthy then

    --local red = redis:new()
	local redis_key = "openresty:healthcheckupstream:"..target.ip..":".. target.port
	--ngx.log(ngx.ERR, "redis_key:"..redis_key)
	--ed:set(redis_key,"healthy")
    local ok, err = ngx.timer.at(5, function(premature)
        redis_healthcheck_change(premature, redis_key, "healthy")
    end)
    if not ok then
        ngx.log(ngx.ERR, "Failed to create timer: ", err)
    end
        -- target changed state, or was added
        ngx.log(ngx.INFO,"Target switched to healthy: ",
            target.ip, ":", target.port, " ", target.hostname)
    elseif eventname ==  checker.events.unhealthy then
	    local redis_key = "openresty:healthcheckupstream:"..target.ip..":".. target.port
        local ok, err = ngx.timer.at(5, function(premature)
            redis_healthcheck_change(premature, redis_key, "unhealthy")
            end)
    if not ok then
        ngx.log(ngx.ERR, "Failed to create timer: ", err)
    end
        ngx.log(ngx.ERR,"Target switched to unhealthy: ",
            target.ip, ":", target.port, " ", target.hostname)
    else
        -- unknown event
	ngx.log(ngx.ERR, eventname)
    end
end

function _M.healthcheck_logic(healthcheckconf)
    local ok, err = we.configure({
        shm = "my_worker_events",
        interval = 0.1
    })
    if not ok then
        ngx.log(ngx.ERR, "failed to configure worker events: ", err)
        return
    end

    local shm = ngx.shared.healthcheck_store -- 假设已经创建了名为'my_shm'的共享内存区域
    --设置事件处理函数
    we.register(event_handler, checker.EVENT_SOURCE)
    -- 定义健康检查配置
    checker = healthcheck.new({
        name = "gerrit_upstream",
        shm_name = "healthcheck_store",
        checks = {
            active = {
                type = healthcheckconf.type,
            timeout = healthcheckconf.timeout,
                healthy  = {
                    successes = healthcheckconf.healthy_success,
                interval = healthcheckconf.interval,
                },
                unhealthy  = {
                interval = healthcheckconf.interval,
                    tcp_failures = healthcheckconf.healthy_failures,
                }
            },
        }
    })
    --启动健康检查
    checker:start()
    -- checker:add_target("10.134.11.223", 29418)
    -- checker:add_target("192.168.22.245", 29418)
    for k,v in ipairs(healthcheckconf.target) do
        checker:add_target(v.host, v.port)
        ngx.log(ngx.INFO, "healthcheck is running: host:".. v.host .. ":".. v.port  )
    end
end

return _M
