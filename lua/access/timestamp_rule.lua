local _M = {}

function _M.timestamp_logic(denyConf)
    -- 获取当前时间
    local now = os.time()

    -- 定义允许的时间段
    local time_range = {
        start_date = denyConf.start_date,        -- 开始日期
        stop_date = denyConf.stop_date,          -- 结束日期
        effective_time = denyConf.effective_time -- 每天的有效时间范围
    }

    -- 将日期字符串转换为时间戳
    local function parse_date(date_str)
        local year, month, day = date_str:match("(%d+)-(%d+)-(%d+)")
        return os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = 0, min = 0, sec = 0 })
    end

    -- 将时间字符串转换为秒数
    local function parse_time(time_str)
        local hour, min, sec = time_str:match("(%d+):(%d+):(%d+)")
        return tonumber(hour) * 3600 + tonumber(min) * 60 + tonumber(sec)
    end

    -- 解析日期和时间范围
    local start_timestamp = parse_date(time_range.start_date)
    local stop_timestamp = parse_date(time_range.stop_date) + 86400 -- 结束日期的 23:59:59
    local start_time = parse_time(time_range.effective_time[1])
    local stop_time = parse_time(time_range.effective_time[2])

    -- 获取当前日期的零点时间戳
    local today_zero = os.time({ year = os.date("%Y", now), month = os.date("%m", now), day = os.date("%d", now), hour = 0, min = 0, sec = 0 })
    local current_time = now - today_zero -- 当前时间的秒数

    -- 判断当前时间是否在配置的日期和时间范围内
    if now >= start_timestamp and now <= stop_timestamp then
        if current_time >= start_time and current_time <= stop_time then
            -- 在配置的时间范围内
            return true
        end
    end
    return false
end

return _M
