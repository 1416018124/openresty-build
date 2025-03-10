local conf = ngx.shared.conf
local get_conf = require("get_conf")
local cjson = require "cjson"
local util = require "util"
local healthcheck = require "resty.healthcheck"
local healthcheckconftable = get_conf.get_defaultConf("healthcheck")
local init_upstream = require("init_upstream_healthcheck")
local init_worker_phase_entrance = require("init_worker_phase_entrance")
if ngx.worker.id() == 0 then
    init_worker_phase_entrance.update_lua_conf()
    if not healthcheck then
        ngx.log(ngx.INFO,"healthcheck is not set")
        return
    end
    
    if conf == nil then
        ngx.log(ngx.INFO,"conf is nil")
        return
    end
    
    for k,h_conf in ipairs(healthcheckconftable) do
        if h_conf.health_on then
            ngx.log(ngx.INFO, "healthcheck is running")
        end
    end

end
