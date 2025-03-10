local _M = {}

local util = require "util"

local function is_matching_condition(ip_info, condition)
    -- 检查国家
    if condition.country then
        local country_name = ip_info.country and ip_info.country.names and ip_info.country.names["zh-CN"]
        if country_name ~= condition.country then
            return false
        end
    end
    -- 检查省份
    if condition.province then
        local province_name = ip_info.subdivisions and ip_info.subdivisions[1] and ip_info.subdivisions[1].names and ip_info.subdivisions[1].names["zh-CN"]
        if province_name then
            -- 去除省份名称后面可能的 "省" 字进行比较
            province_name = province_name:gsub("省$", "")
            province_name = province_name:gsub("市$", "")
            if province_name ~= condition.province then
                return false
            end
        else
            return false
        end
    end
    -- 检查城市
    if condition.city then
        local city_name = ip_info.city and ip_info.city.names and ip_info.city.names["zh-CN"]
        if city_name ~= condition.city then
            return false
        end
    end
    return true
end

local function Query_ip(ip)
    local cached_info = Lcache:get(ip)
    if cached_info then
       return  cached_info
    end

    if not Geo.initted() then
        Geo.init(util.defaultConf.mmdb)
    end
    local res,err = Geo.lookup(ip)
    if not res then
        return "none"
    end
    local expiration_time = 86400
    Lcache:set(ip, res, expiration_time)
    ngx.log(ngx.DEBUG, "cached IP info for", ip)
    return res
end

local function is_zone_allowed(ips, denyConf)
    if #ips == 0 then
        return false
    end
    for _, ip in ipairs(ips) do
        --if not Geo.initted() then
        --    Geo.init("/usr/local/openresty/nginx/GeoLite2-City.mmdb")
        --end
        --local res, err = Geo.lookup(ip)

        --if not res then
        --    ngx.status = 200
        --    return "none"
        --end
        local res =  Query_ip(ip)

        --ngx.say("IP: ", ip)
	--ngx.say("Country: ", res.country.names["zh-CN"] or "Unknown")
        --ngx.say("subdivisions", res.subdivisions[1].names["zh-CN"] or "Unknown")
        --ngx.say("City: ", res.city.names["zh-CN"] or "Unknown")
	
	for _, condition in ipairs(denyConf.zone) do
	    if is_matching_condition(res, condition) then
	        return "hit"
	    end
	end
    end
    return "miss"
end

function _M.zone_logic(denyConf)
    local zone_rule = "allow"
    local start_time = ngx.now()
    -- 获取客户端 IP
    local client_ip = ngx.var.remote_addr
    local real_ip = ngx.var.http_x_real_ip             -- X-Real-IP 头中的 IP
    local forwarded_for = ngx.var.http_x_forwarded_for -- X-Forwarded-For 头中的 IP 列表

    local ip_list = {}
    -- remote_addr,http_x_forwarder_for,http_x_real_ip
    for _, ip_type in ipairs(denyConf.check_ip) do
        if ip_type == "remote_addr" then
            table.insert(ip_list, client_ip)
        elseif ip_type == "real_ip" then
            table.insert(ip_list, real_ip)
        elseif ip_type == "http_x_forwarder_for" then
            if forwarded_for and forwarded_for ~= "" then
                -- 按逗号分隔字符串
                for ip in string.gmatch(forwarded_for, "[^,]+") do
                    -- 去除 IP 两端的空格（如果有）
                    ip = string.gsub(ip, "^%s*(.-)%s*$", "%1")
                    -- 将 IP 添加到列表中
                    table.insert(ip_list, ip)
                end
            end
        end
    end

    -- 检查客户端 IP 是否在list范围内
    local res = is_zone_allowed(ip_list, denyConf)
    ngx.log(ngx.ERR,res)
    if res == "hit" and denyConf.acl_type == "deny" then
            --ngx.status = 403
            --ngx.say("Access denied: zone not allowed.")
            --ngx.exit(ngx.HTTP_FORBIDDEN)
            zone_rule =  "deny"
    elseif res == "miss" and denyConf.acl_type == "allow" then
            --ngx.status = 403
            --ngx.say("Access denied: zone not allowed.")
            --ngx.exit(ngx.HTTP_FORBIDDEN)
            zone_rule =  "deny"
    else
            zone_rule =  "allow"
    end
    local end_time = ngx.now()
    local elapsed_time = math.floor((end_time - start_time) * 1000)
    ngx.var.zone_elapsed = elapsed_time
    return zone_rule,ip_list
end

return _M

