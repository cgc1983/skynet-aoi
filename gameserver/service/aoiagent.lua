package.path = package.path..";"..PROJ_ROOT.."/utils/?.lua"..";"..PROJ_ROOT.."/handler/?.lua"..";"

local skynet = require "skynet"
local cjson  = require "cjson"

local aoiutil = require "aoiutil"

require "functions"

local aoi,n = ...
local OBJ
local CMD={}

local old_pos

local runfork=true

math.randomseed(tostring(os.time()+n):reverse():sub(1, 7))


function CMD.updateaoiobj(obj)
    -- skynet.error("aoi agent function updateaoiobj=",OBJ.tempid,",data=",cjson.encode(obj))
end

function CMD.delaoiobj(obj)
    -- skynet.error("aoi agent function delaoiobj",OBJ.tempid,",data=",cjson.encode(obj))
end

function CMD.addaoiobj(obj)
    -- skynet.error("aoi agent function addaoiobj",OBJ.tempid,",data=",cjson.encode(obj))
end

function CMD.updateaoilist(obj)
    -- skynet.error("aoi agent function updateaoilist",OBJ.tempid,",data=",cjson.encode(obj))
end


function CMD.start(obj1,move)
    OBJ = obj1
    OBJ.movement.pos = {
        x=math.random(RECT_X.s,RECT_X.e),
        y=math.random(RECT_Y.s,RECT_Y.e),
        z=0,
    }
    OBJ.agent=skynet.self()
    local ok = pcall(skynet.call,aoi,'lua','enter',OBJ)

    local x={1,-1}
    skynet.fork(function()
        while runfork do
            local r1 = math.random(1,2)
            local r2 = math.random(10,30)
            local r3 = math.random(1,2)
            if r1==1 then
                OBJ.movement.pos.x = OBJ.movement.pos.x + r2*x[r3]
                --skynet.error("player",OBJ.tempid,"x轴:",r2*x[r3])
            else
                OBJ.movement.pos.y = OBJ.movement.pos.y + r2*x[r3]
                --skynet.error("player",OBJ.tempid,"y轴:",r2*x[r3])
            end

            local ok = pcall(skynet.call,aoi,'lua','enter',OBJ)
            skynet.sleep(3)
            if OBJ.movement.pos.x<10 or OBJ.movement.pos.y< 10 then
                OBJ.movement.pos.x=math.random(RECT_X.s,RECT_X.e)
                OBJ.movement.pos.y=math.random(RECT_Y.s,RECT_Y.e)
            end
        end
    end)
    return "ok"
end

function CMD.stop()
    runfork=false
    return "ok"
end

skynet.start(function()

    skynet.dispatch("lua", function(_,_, command, ...)
        --skynet.trace()
        local f = CMD[command]

        local ret = f(...)

        if ret then
            skynet.ret(skynet.pack(ret))
        end
    end)
end)
