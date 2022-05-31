local cjson     = require "cjson"
local string    = require "string"
local table_new = require "table.new"
local table     = require "table"
local jwt       = require "resty.jwt"
local redis     = require "redis"
local keysutils = require "keysutils"
local utilsdate = require "utilsdate"
local utils     = require "utils"

require "functions"

local _M={}

function _M.access()
    local headers=ngx.req.get_headers()
    local clientIP = headers["x-forwarded-for"]
    if clientIP == nil or string.len(clientIP) == 0 or clientIP == "unknown" then
           clientIP = headers["Proxy-Client-IP"]
    end
    if clientIP == nil or string.len(clientIP) == 0 or clientIP == "unknown" then
           clientIP = headers["WL-Proxy-Client-IP"]
    end
    if clientIP == nil or string.len(clientIP) == 0 or clientIP == "unknown" then
           clientIP = ngx.var.remote_addr
    end
    -- 对于通过多个代理的情况，第一个IP为客户端真实IP,多个IP按照','分割
    if clientIP ~= nil and string.len(clientIP) >15  then
           local pos  = string.find(clientIP, ",", 1)
           clientIP = string.sub(clientIP,1,pos-1)
    end
  --判断是否内网ip
    local privateip = utils.isprivateip(clientIP)
    if privateip then
        return true
    end
    return false
end

return _M
