local conf = ngx.shared.conf

local uri = ngx.var.uri
local domain = string.match(uri, "/([^/]+)$")
ngx.log(ngx.ERR, domain)
ngx.say(conf:get(domain))
