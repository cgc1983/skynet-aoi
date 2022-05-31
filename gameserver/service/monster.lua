-- 怪物
--
local skynet     = require "skynet"
local datacenter = require "skynet.datacenter"
local cjson      = require "cjson"


local aoi
local id = ...

id = math.floor(tonumber(id))

local CMD = {}
local map_width, map_height

local x, y, sx, sy

local function move()
    x = x + sx
    y = y + sy
    if x < 0 then
        sx = -sx
        x = 0
    end
    if x > map_width then
        sx = -sx
        x = map_width
    end
    -- # 纵向出界
    if y <= 0 then --# 离开了地图下边
        sy = -sy
        y = 0
    end

    if y >= map_height then -- # 离开了地图上边
        sy = -sy
        y = map_height
    end
end

math.randomseed(tostring(os.time() + id):reverse():sub(1, 7))

function CMD.updateaoiobj(obj)
    -- skynet.error("monster updateaoiobj:",cjson.encode(obj))
    --skynet.error("monster agent function updateaoiobj=","my id=",id,",my post=",cjson.encode(POS),obj.tempid,",data=",cjson.encode(obj))
end

function CMD.delaoiobj(obj)
    -- skynet.error("monster delaoiobj:",cjson.encode(obj))
    --skynet.error("monster agent function delaoiobj=","my id=",id,",my post=",cjson.encode(POS),obj.tempid,",data=",cjson.encode(obj))
end

function CMD.addaoiobj(user_id, obj)
    -- skynet.error("monster addaoiobj user_id=",user_id,",obj=",cjson.encode(obj))
    --skynet.error("monster agent function addaoiobj=","my id=",id,",my post=",cjson.encode(POS),obj.tempid,",data=",cjson.encode(obj))
end

function CMD.updateaoilist(obj)
    --skynet.error("monster agent function updateaoilist",obj.tempid,",data=",cjson.encode(obj))
end

function CMD.start(conf)

    local total_count = math.random(100, 200)
    map_width = conf.width
    map_height = conf.height
    -- local ok = pcall(skynet.call,aoi,'lua','enter',conf)

    x = math.random(1, map_width)
    y = math.random(1, map_height)

    sx = math.random(10, 20)
    -- sy=math.random(10,20)
    sy = 0


    local r = math.random(1, 255)
    local g = math.random(1, 255)
    local b = math.random(1, 255)

    skynet.fork(function()
        while total_count > 0 do
            local r1 = math.random(1, 2)
            local r2 = math.random(10, 100)
            local r3 = math.random(1, 2)


            move()

            local obj = {
                agent = skynet.self(),
                tempid = id,
                movement = {
                    mode = "m",
                    pos = {
                        x = x,
                        y = y,
                        z = 0,
                    },
                },
                colors = { r, g, b },
                type = 2,
                dir = sx,
            }

            total_count = total_count - 1
            if total_count > 0 then
                local ok = pcall(skynet.call, aoi, 'lua', 'enter', obj)
            else
                local ok = pcall(skynet.send, aoi, 'lua', 'leave', obj)
            end
            skynet.sleep(10)
        end
    end)
    return "ok"
end

skynet.start(function()
    aoi = datacenter.get("main-scene")
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command])
        local ret = f(...)

        if ret then
            skynet.ret(skynet.pack(ret))
        end

    end)
    collectgarbage()
end)
