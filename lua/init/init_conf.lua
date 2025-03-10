-- add luaPath
local file_path = "/usr/local/openresty/nginx/conf/default.conf"
local current_path = debug.getinfo(1,"S").source:sub(2)
local luaPath = current_path:match("^(.*[/\\]lua/)")
package.path = package.path.. ";".. luaPath.. "util/?.lua;" .. luaPath.. "access/?.lua;" .. luaPath.. "init/?.lua;" .. luaPath .. "lualib/?.lua;"
package.cpath = package.cpath .. ";" .. luaPath .. "lualib/?.so;"
--package.path = package.path .. ";" .. pulginpath .. "init/?.lua;" .. pulginpath .. "access/?.lua;" .. pulginpath .. "util/?.lua"

local cjson = require "cjson"
local util = require "util"
local conf = ngx.shared.conf
local cjson = require "cjson"



local function init_default(defaultTable)
    local redisConf = {}
    if not defaultTable.redis then
        redisConf = {
            type = "solo",
            host = {
                host = "127.0.0.1",
                port = 6379
            }
        }
    else
        redisConf = defaultTable.redis
    end
    local defaultConf = {
            rule_conf_path = defaultTable.rule_conf_path or "/usr/local/openresty/nginx/conf/lua.conf",
            mmdb = defaultTable.mmdb or "/usr/local/openresty/nginx/GeoLite2-City.mmdb",
            redis = redisConf
        }
    local defaultConfJsonStr = cjson.encode(defaultConf)
    local ok, err = conf:set("default", defaultConfJsonStr)
    if not ok then
        ngx.log(ngx.ERR, "Faild to set value in shared memory:", err)
    end
end

local function init_healthcheck(luapath)
    local file_content = util.readfile(luapath)
    if not file_content then
         ngx.log(ngx.WARN, luapth .. " is not ")
         return
     end
    
    local json_content = cjson.decode(file_content)
    if not json_content then
        ngx.log(ngx.WARN, luapath .. ": format is not json")
        return
    end
    local healthchecktable = {}
    for _, domain_conf in pairs(json_content) do
        local domain = domain_conf.domain
        -- 判断是否有主动健康检查的功能，需要init_worker_by_lua初始化，写入到health共享内存中
        local healthcheckconf = domain_conf.healthcheck
        if healthcheckconf then
            local hc = init_health(healthcheckconf)
            hc["domain"] = domain
            table.insert(healthchecktable, hc)
        end
    end
    
    local healthcheckstr = cjson.encode(healthchecktable)
    local ok, err = conf:set("healthcheck", healthcheckstr)
    if not ok then
        ngx.log(ngx.ERR, "Failed to set value in shared memory: ", err)
    end
end


local file_content = util.readfile(file_path)
ngx.log(ngx.INFO, file_content)

if not file_content then
     ngx.log(ngx.EMERG, file_path .. " is not ")
     return
 end

local json_content = cjson.decode(file_content)
if not json_content then
    ngx.log(ngx.EMERG, file_path .. ": format is not json")
    return
end

local defaultconfTable = cjson.decode(file_content)
init_default(defaultconfTable)
init_healthcheck(defaultconfTable.rule_conf_path)

Geo = require "resty.maxminddb"
Geo.init(defaultconfTable.mmdb)

local lrucache = require "resty.lrucache"
local err
Lcache, err = lrucache.new(1000)
if not Lcache then
	ngx.log(ngx.ERR, "failed to create the cache:", err)
	return
end
