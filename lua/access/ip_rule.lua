local ip_utils = require "resty.iputils"
local cidr = require "libcidr-ffi"

local _M = {}

-- 判断 IP 是否在允许的列表中
local function is_ip_allowed(ips, denyConf)
    if #ips == 0 then
        return false
    end
    for _, ip in ipairs(ips) do
        -- 判断 IPv4
        local p_list = ip_utils.parse_cidrs(denyConf.ipv4_list)
        if ip:find(":") == nil then
            if ip_utils.ip_in_cidrs(ip, p_list) then
                return true
            end
        else
            -- 判断 IPv6
            --local p_list = ip_utils.parse_cidrs(denyConf.ipv6_list)
            --if ip_utils.ip_in_cidrs(ip, p_list) then
            --    return true
            --end
            for _,ipcidr in ipairs(denyConf.ipv6_list) do
                ngx.log(ngx.ERR, "ip", ip, "; ipcidr:", ipcidr)
                ngx.log(ngx.ERR, cidr.contains(cidr.from_str(ip), cidr.from_str(ipcidr)))
                if cidr.contains(cidr.from_str(ip), cidr.from_str(ipcidr)) then
                    return true
                end
            end
        end
    end
    return false
end

function _M.ip_logic(denyConf)
    local ip_rule = "allow"
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
    if is_ip_allowed(ip_list, denyConf) then
        if denyConf.acl_type == "deny" then
            ip_rule =  "deny"
        else
            ip_rule = "allow"
        end
    else
        ip_rule =  "pending"
    end
    local end_time = ngx.now() 
    local elapsed_time = math.floor((end_time - start_time) * 1000)
    ngx.var.ip_elapsed = elapsed_time
    return ip_rule, ip_list
end

return _M
