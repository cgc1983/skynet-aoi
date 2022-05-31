local request = {}
local http = require "resty.http"

-- http请求函数
function request.get(url,body)
    local httpc = http.new()
    local methods = "GET"
    local res, err = httpc:request_uri(url, {
        ssl_verify = false,
        method = methods,
        headers = {
          ["Content-Type"] = "application/x-www-form-urlencoded",
        }
    })
    if not res then
        ngx.log(ngx.INFO,"failed to request: ", err)
        return false
    else
        return res.body
    end
end

function request.post(url,body)
    local httpc = http.new()
    local body = body or ""
    local res, err = httpc:request_uri(url, {
        ssl_verify = false,
        method =  "POST",
        body = body,
        headers = {
          ["Content-Type"] = "application/json",
        }
    })
    if not res then
        ngx.log(ngx.INFO,"failed to request: ", err)
        return false
    else
        return res.body
    end
end

return request
