package.path = package.path..";"..PROJ_ROOT.."/utils/?.lua"..";"..PROJ_ROOT.."/handler/?.lua"..";"


local skynet = require "skynet"
local cjson  = require "cjson"

local CMD={}


function CMD.updateaoiinfo(obj)
    -- skynet.error("+++++++++ map agent updateaoiinfo:",cjson.encode(obj))
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_, command, ...)
        -- skynet.trace()
        -- skynet.error("game agent command = ", command)
        local f = CMD[command]

        local ret = f(...)

        if ret then
            skynet.ret(skynet.pack(ret))
        end
    end)
end)
