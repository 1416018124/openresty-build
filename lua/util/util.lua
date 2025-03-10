local _M = {}
function _M.readfile(file_path)
    local file = io.open(file_path, "r")
    if file then
        local content = file:read("*a")
        file:close()
        return content
    else
        return nil
    end
end

-- 十进制转二进制
local function dec2bin(num)
    -- zore
    if ( num  == 0 )
    then
        return "00000000"
    end

    local t = {}
    while num > 0 do
        local rest = math.floor(num % 2)
        t[#t+1] = rest
        num = (num - rest) / 2
    end
    return string.format("%08d", tonumber(table.concat(t):reverse()))
end

-- 判断IP是否在指定的网段内
local function isIPInRange(ip, subnet, mask)
    local function ipToBinary(ipAddress)
        local binary = ""
        for part in ipAddress:gmatch("%d+") do
            local partNum = tonumber(part)
            binary = binary .. dec2bin(partNum)
            --print("old:".. part.."; 2jinzhi:".. dec2bin(partNum))
        end
        --print(binary)
        return binary
    end

    local ipBinary = ipToBinary(ip)
    local subnetBinary = ipToBinary(subnet)

    -- 使用位运算检查IP地址是否在网段内
    return string.sub(ipBinary, 1, mask) == string.sub(subnetBinary, 1, mask)
end

local function isSubnetMaskString(str)
    local parts = {}
    if str == nil then
        return false
    end
    for part in string.gmatch(str, "([^/]+)") do
        table.insert(parts, part)
    end
    if #parts == 2 then
        local ipPart = parts[1]
        local maskPart = parts[2]
        -- 检查IP部分是否是合法的IP格式
        local ipOctets = {}
        for octet in string.gmatch(ipPart, "([^%.]+)") do
            table.insert(ipOctets, octet)
        end
        if #ipOctets == 4 then
            for _, octet in ipairs(ipOctets) do
                local num = tonumber(octet)
                if num == nil or num < 0 or num > 255 then
                    return false
                end
            end
            -- 检查子网掩码部分是否是合法的数字（这里假设是0 - 32）
            local maskNum = tonumber(maskPart)
            return maskNum ~= nil and maskNum >= 0 and maskNum <= 32
        end
    end
    return false
end

function _M.is_in_SubnetMask(ip, subnet)
    if isSubnetMaskString(subnet) then
        --执行子网判断
        local parts = {}
        for part in string.gmatch(subnet, "([^/]+)") do
            table.insert(parts, part)
        end
        local ipPart = parts[1]
        local maskPart = parts[2]
        return isIPInRange(ip, ipPart, maskPart)
    else
        return ip == subnet
    end
end

function _M.tableLength(t)
    if t == nil then
        return 0
    end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

return _M
