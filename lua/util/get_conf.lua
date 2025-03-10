local conf = ngx.shared.conf
local cjson = require "cjson"
local util = require "util"

local _M = {}

local function get_domainconf(domain)
    local domain_str = conf:get(domain)
    if domain_str == nil then
        return ""
    end
    local domain_table = cjson.decode(domain_str)
    return domain_table
end

function _M.get_domainconf(domain)
    local domain_str = conf:get(domain)
    if domain_str == nil then
        return nil
    end
    local domain_table = cjson.decode(domain_str)
    return domain_table
end

local function app_check(app, shared_data)
    local resp_conf = {}
    if app == "connlimit" then
        local connlimitConf = {}
        local tmp_args = {}
        local default_args = {}
        if not shared_data then
            ngx.log(ngx.INFO, "connlimit is null")
            shared_data.connlimit_on = false
        else
            local default_dry_run = shared_data.dry_run or false
            for _, v in ipairs(shared_data.limit_args) do
                table.insert(tmp_args, {
                    key= v.key,
                    max= v.max or 1000,
                    burst = v.burst or 0,
                    default_conn_delay = v.default_conn_delay or 0.5,
                    limit_location = v.limit_location or "",
                    dry_run = v.dry_run or default_dry_run,
                })
            end
            if util.tableLength(shared_data.default_args) ~= 0 then
                for _, v in ipairs(shared_data.default_args) do
                    table.insert(default_args, {
                        max= v.max or 1000,
                        burst = v.burst or 0,
                        default_conn_delay = v.default_conn_delay or 0.5,
                        limit_location = v.limit_location or "",
                        dry_run = v.dry_run or default_dry_run,
                    })
                end
            end

            connlimitConf = {
                limit_type = shared_data.limit_type or "ip",
                limit_default_user = shared_data.limit_default_user or "anonymous",
                limit_common_on = shared_data.limit_common_on or false,
                limit_args = tmp_args,
                default_args = default_args,
                dry_run = shared_data.dry_run or false,
                connlimit_on = true,
            }
        end
        resp_conf = connlimitConf
    elseif app == "reqlimit" then
        local reqlimitConf = {}
        local tmp_args = {}
        local default_args = {}
        if not shared_data then
            ngx.log(ngx.INFO, "connlimit is null")
            shared_data.reqlimit_on = false
        else
            for _, v in ipairs(shared_data.limit_args) do
                table.insert(tmp_args, {
                    key= v.key,
                    rate= v.rate or "1000r/s",
                    burst = v.burst or 0,
                    duration = v.duration or 2,
                    limit_location = v.limit_location or ""
                })
            end
            if util.tableLength(shared_data.default_args) ~= 0 then
                for _, v in ipairs(shared_data.default_args) do
                    table.insert(default_args, {
                        rate= v.rate or "1000r/s",
                        burst = v.burst or 0,
                        default_conn_delay = v.default_conn_delay or 0.5,
                        limit_location = v.limit_location or "",
                        dry_run = v.dry_run or false,
                    })
                end
            end
            reqlimitConf = {
                limit_type = shared_data.limit_type or "ip",
                limit_default_user = shared_data.limit_default_user or "anonymous",
                limit_args = tmp_args,
                default_args = default_args,
                dry_run = shared_data.dry_run or false,
                limit_common_on = shared_data.limit_common_on or false,
                reqlimit_on =  true,
            }
            resp_conf = reqlimitConf
            end
    elseif app == "basic" then
        local basicConf = {
            service = shared_data.service or "default",
            ip_deny = shared_data.ip_deny or false
        }
        resp_conf = basicConf
    end
    return resp_conf
end

function _M.app(app)
    local domain = ngx.var.host
    local domain_table = get_domainconf(domain)
    if domain_table == "" then
        return nil
    end
    return app_check(app, domain_table[app])
end

function _M.get_defaultConf(app)
    local default_str = conf:get(app)
    if default_str == nil then
        return nil
    end
    local default_table = cjson.decode(default_str)
    return default_table
end

local function get_defaultConf(app)
    local default_str = conf:get(app)
    local default_table = cjson.decode(default_str)
    return default_table
end


function _M.get_deny()
    local domainTable = get_domainconf(ngx.var.host)
    if not domainTable then
        return nil
    else
        local denyConf = {
            domain = domainTable.domain,
            acl_type = domainTable.acl_type or "deny",
            start_date = domainTable.start_date or "1970-01-01",
            stop_date = domainTable.stop_date or "1970-01-01",
            effective_time = domainTable.effective_time or {},
            check_ip = domainTable.check_ip or {},
            ipv4_list = domainTable.ipv4_list or {},
            ipv6_list = domainTable.ipv6_list or {},
            zone = domainTable.zone or {},
        }
        return denyConf
    end
    return nil
end

return _M
