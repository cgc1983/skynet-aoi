local redisc = require "resty.rediscluster"

local _M = {}

function _M.new(_, cnf)
    local red, err = redisc:new(cnf)
    if err then
        ngx.log(ngx.INFO, "failed to create: ", err)
        return nil
    end
    return red
end


return _M