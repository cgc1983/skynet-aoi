local keysutils    = require "keysutils"
local redis        = require "redis"
local cjson = require "cjson"
local config = require "config"
local resty_lock = require "resty.lock"

require "functions"

local _M={}
function _M.filter()
    local chunk, eof = ngx.arg[1], ngx.arg[2]

    -- 定义全局变量，收集全部响应
    if ngx.ctx.buffered == nil then
        ngx.ctx.buffered = {}
    end

    -- 如果非最后一次响应，将当前响应赋值
    if chunk ~= "" and not ngx.is_subrequest then
        table.insert(ngx.ctx.buffered, chunk)

        -- 将当前响应赋值为空，以修改后的内容作为最终响应
        ngx.arg[1] = nil
    end

    -- 如果为最后一次响应，对所有响应数据进行处理
    if eof then
        -- 获取所有响应数据
        local body = table.concat(ngx.ctx.buffered)
        ngx.ctx.buffered = nil

        -- 进行你所需要进行的处理
        ngx.log(ngx.DEBUG,"body=",body)
        -- body = tod
        local ok,jsonbody = pcall(cjson.decode,body)
        if ok then
            if jsonbody.errcode and jsonbody.errcode>0 and not jsonbody.errmsg then
                 jsonbody.errmsg = config.get("errmsg",'e'..jsonbody.errcode)
            end
            -- 重新赋值响应数据，以修改后的内容作为最终响应
            ngx.arg[1] = cjson.encode(jsonbody)
        else
            ngx.arg[1] = body
        end


    end
end
return _M