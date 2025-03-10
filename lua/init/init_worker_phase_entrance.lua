local rlock = require "resty.lock"
local lfs = require "lfs"
local cjson = require "cjson"
local iputils = require "resty.iputils"

local dict_name = "conf"
local conf = ngx.shared.conf
local lock, _ = rlock:new(dict_name, { ["timeout"] = 0 })
local conf_key = "share_dict_conf"
local lastmod = "conf:last:modified"
local delay = 60
local get_conf = require "get_conf"
local luaconf = get_conf.get_defaultConf("default").rule_conf_path

local function isconfread()
    local attribute = lfs.attributes(luaconf)
    if not attribute or type(attribute) ~= "table" then
        ngx.log(ngx.ERR, "------NO CONFIGURE FILE FOUND at " .. luaconf .. "------")
        return false
    end

    local timekey = lastmod .. luaconf
    local cache_time = conf:get(timekey)
    if not cache_time then
        conf:set(timekey, tostring(attribute.modification))
        ngx.log(ngx.INFO, "First load for " .. luaconf .. ". Loading ...")
        return true
    end

    if tostring(attribute.modification) == cache_time then
        ngx.log(ngx.DEBUG, "No change for " .. luaconf)
        return false
    else
        conf:set(timekey, tostring(attribute.modification))
        ngx.log(ngx.INFO, "Modified " .. luaconf .. ". Loading ...")
        return true
    end
end

local function freelock(elapsed)
    if elapsed then
        local ok, err = lock:unlock()
        if not ok then
            ngx.log(ngx.ERR, "failed to unlock: ", err)
        end
    end
end

local function is_valid_ip(ip)
    return  iputils.ip2bin(ip) ~= nil
end

-- 检查 CIDR 段是否合法
local function is_valid_cidr(cidr)
    local ip, mask = cidr:match("([^/]+)/?(%d*)")
    if not ip or not mask then
        return false
    end

    local valid_ip = is_valid_ip(ip)
    if not valid_ip then
        return false
    end
    if mask ~= "" then
        -- 检查掩码是否有效
        mask = tonumber(mask)
        return mask and mask >= 0 and mask <= 128 -- 对于 IPv6
                or (mask >= 0 and mask <= 32) -- 对于 IPv4
    end
end

local function filter_valid_cidrs(cidr_list)
    if not cidr_list then
        return 
    end
    local valid_cidrs = {}
    for _, cidr in ipairs(cidr_list) do
        if is_valid_cidr(cidr) then
            table.insert(valid_cidrs, cidr)
        end
    end
    return valid_cidrs
end

local function conf_insert(domainconfTable)
    for _, server in ipairs(domainconfTable) do
        dconf.domain = server.domain
         local domain_str_conf = cjson.encode(dconf)
             ngx.log(ngx.DEBUG, domain_str_conf)
             if conf:get(dconf.domain) ~= domain_str_conf then
                 conf:set(dconf.domain, domain_str_conf)
             end
    end
end

local function read_conf_file()
    local elapsed, err = lock:lock(conf_key)
    local lcf = isconfread()
    if not lcf then
        ngx.log(ngx.DEBUG, luaconf .. "is not update")
        freelock(elapsed)
        return
    end

    local file = io.open(luaconf, "r")
    if not file then
        ngx.log(ngx.ERR, luaconf .. "is not open,please check")
        freelock(elapsed)
        return
    end
    local content = file:read("*a")
    file:close()
    local domainconfTable = cjson.decode(content)
    if domainconfTable == nil then
        ngx.log(ngx.ERR, luaconf .. "is not json format,please check")
        freelock(elapsed)
        return
    end
    --conf_insert(domainconfTable)
    for _, v in pairs(domainconfTable) do
        local domain = v["domain"]
        local domain_str_conf = cjson.encode(v)
        if conf:get(domain) ~= domain_str_conf then
            conf:set(domain, domain_str_conf)
            ngx.log(ngx.INFO, "Load: " .. domain .. ":conf : " .. domain_str_conf)
        end
    end
    freelock(elapsed)
end

local handler
handler           = function()
    if ngx.worker.id() == 0 then
        read_conf_file()
        local ok, timeErr = ngx.timer.at(delay, handler)
        if not ok then
            ngx.log(ngx.ERR, "failed to create timer: ", timeErr)
            return
        end
    end
end

local ok, timeErr = ngx.timer.at(0, handler)
if not ok then
    ngx.log(ngx.ERR, "failed to create timer: ", timeErr)
    return
end

local _M = {}
function _M.update_lua_conf()
    if ngx.worker.id() == 0 then
        read_conf_file()
    end
end

return _M
