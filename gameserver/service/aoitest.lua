package.path = package.path..";"..PROJ_ROOT.."/utils/?.lua"..";"..PROJ_ROOT.."/handler/?.lua"..";"

local skynet = require "skynet"
local cjson  = require "cjson"

require "functions"

local CMD={}

local s,e=...
s=math.floor(tonumber(s))
e=math.floor(tonumber(e))

math.randomseed(tostring(os.time()):reverse():sub(1, 7))

skynet.start(function()
    skynet.fork(function()
        for i=s,e do
        skynet.call("redisd","lua","incmonster",1)
        local monster = skynet.newservice("monster",i)
        skynet.call(monster,"lua","start",{width=1344*4,height=750*4})
        end

        skynet.exit()
    end)
    skynet.dispatch("lua", function(_,_, command, ...)
        --skynet.trace()
        local f = CMD[command]

        local ret = f(...)

        if ret then
            skynet.ret(skynet.pack(ret))
        end
    end)
end)
