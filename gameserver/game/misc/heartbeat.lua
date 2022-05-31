local skynet = require "skynet"
local cjson  = require "cjson"
local heartbeat={}

function heartbeat.ping(cmd)
    skynet.error("heartbeat ping",cjson.encode(cmd))
    return {
        c="heartbeat",
        m="pong",
        data={},
    }
end


return heartbeat