local skynet = require "skynet"

local user = {}

function user.loadcontext(cmd)
    return {
        c="user",
        m="loadcontext",
        data={
            errcode=0,
        }
    }
end




return user