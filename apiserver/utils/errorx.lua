--API 通用错误处理

local cjson = require "cjson"
local _M={}

local ERR_MAP={
    [500]="服务器内部错误",
    [400]="参数错误",
}

function _M.get_errmsg(code)
    assert(ERR_MAP[code])
    return {errcode=code,errmsg=ERR_MAP[code],data={},}
end

function _M.say_success(data)
    local resp = {errocode=0,errmsg="",data=data,}
    ngx.say(cjson.encode(resp))
end

function _M.say500()
    ngx.say(cjson.encode(_M.get_errmsg(500)))
end

function _M.say(errcode)
    ngx.say(cjson.encode(_M.get_errmsg(errcode)))
end

return _M
