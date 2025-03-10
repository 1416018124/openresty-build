local ctx = ngx.ctx
local lim = ctx.limit_conn
local function timer_callback()
    if lim then
        -- if you are using an upstream module in the content phase,
        -- then you probably want to use $upstream_response_time
        -- instead of ($request_time - ctx.limit_conn_delay) below.
        --local latency = tonumber(ngx.var.request_time) - ctx.limit_conn_delay
        local key = ctx.limit_conn_key
        assert(key)
        local conn, err = lim:leaving(key)
        --ngx.log(ngx.ERR, conn)
        if not conn then
            ngx.log(ngx.ERR,
                    "failed to record the connection leaving ",
                    "request: ", err)
        end
    end
end

local ok, err = ngx.timer.at(0, timer_callback)
if not ok then
    ngx.log(ngx.ERR, "Failed to create timer: ", err)
end
