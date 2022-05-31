local global = require "global"

local appname = global.get_appname()


local keysutils={}

function keysutils.get_user_token(uid, deviceid)
    local key = string.format("%s:userserver:token:%s:%s", appname, deviceid, uid)
    return key
end

return keysutils






















