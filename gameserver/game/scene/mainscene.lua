local skynet = require "skynet"
local cjson = require "cjson"
local mainscene={}

function mainscene.move(cmd)
    local aoi = GAME_SCENE["main-scene"]
    local agent = skynet.self()
    POS=cmd.data.pos
    local ok = pcall(skynet.call,aoi,'lua','enter',{
        tempid=UID,
        agent=agent,
        movement={
            mode="wm",
            pos=cmd.data.pos,
        },
        type=1,
    })
end

return mainscene