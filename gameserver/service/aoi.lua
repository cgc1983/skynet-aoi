package.path = package.path .. ";" .. PROJ_ROOT .. "/utils/?.lua;" .. PROJ_ROOT .. "/?.lua;" .. PROJ_ROOT .. "/service/?.lua;"
local skynet = require "skynet"
local queue = require "skynet.queue"
local cjson = require "cjson"
local profile = require "skynet.profile"

require "skynet.manager"

require "functions"

function table.empty(tlb)
    local t = tlb or {}
    for k, v in pairs(tlb) do
        return false
    end

    return true
end

local enumtype =
{
    CHAR_TYPE_PLAYER = 1,
    CHAR_TYPE_MONSTER = 2,
}


local CMD = {}
local OBJ = {}
local playerview = {}
local monsterview = {}
local aoi
local update_thread
local need_update
local map_name = ...
local mapagent
local luaqueue = queue()

local AOI_RADIS = 800
local AOI_RADIS2 = AOI_RADIS * AOI_RADIS
local LEAVE_AOI_RADIS2 = AOI_RADIS2 * 4

local function DIST2(p1, p2)
    return ((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y) + (p1.z - p2.z) * (p1.z - p2.z))
end

skynet.register_protocol {
    name = "text",
    id = skynet.PTYPE_TEXT,
    pack = function(text) return text end,
    unpack = function(buf, sz) return skynet.tostring(buf, sz) end,
}

--怪物移动的时候通知玩家信息
local function updateviewmonster(monstertempid)
    -- skynet.error("updateviewmonster",monstertempid)
    if monsterview[monstertempid] == nil then return end
    local myobj = OBJ[monstertempid]
    local mypos = myobj.movement.pos
    --离开他人视野
    local leavelist = {}
    --进入他人视野
    local enterlist = {}
    --通知他人自己移动
    local movelist = {}

    local othertempid
    local otherpos
    local otheragent
    local otherobj
    for k, v in pairs(monsterview[monstertempid]) do
        othertempid = OBJ[k].tempid
        otherpos = OBJ[k].movement.pos
        otheragent = OBJ[k].agent
        otherobj = {
            tempid = othertempid,
            agent = OBJ[k].agent,
        }
        local distance = DIST2(mypos, otherpos)
        if distance <= AOI_RADIS2 then
            if not v then
                monsterview[monstertempid][k] = true
                playerview[k][monstertempid] = true
                table.insert(enterlist, OBJ[k])
            else
                table.insert(movelist, otheragent)
            end
        elseif distance > AOI_RADIS2 and distance <= LEAVE_AOI_RADIS2 then
            if v then
                monsterview[monstertempid][k] = false
                playerview[k][monstertempid] = false
                table.insert(leavelist, otherobj)
            end
        else
            if v then
                table.insert(leavelist, otherobj)
            end
            monsterview[monstertempid][k] = nil
            playerview[k][monstertempid] = nil
        end
    end

    --离开他人视野
    for _, v in pairs(leavelist) do
        skynet.send(v.agent, "lua", "delaoiobj", myobj.tempid, "updateviewmonster")
    end

    --重新进入视野
    for _, v in pairs(enterlist) do
        skynet.send(v.agent, "lua", "addaoiobj", myobj, "updateviewmonster")
    end

    --视野范围内移动
    for _, v in pairs(movelist) do
        skynet.send(v, "lua", "updateaoiobj", myobj)
    end

    skynet.send(myobj.agent, "lua", "updateaoilist", myobj.tempid, enterlist, leavelist)
end

--根据对象类型插入table
local function inserttotablebytype(t, v, type)
    if type ~= enumtype.CHAR_TYPE_PLAYER then
        table.insert(t.monsterlist, v)
    else
        table.insert(t.playerlist, v)
    end
end

--观看者坐标更新的时候
--根据距离情况通知他人自己的信息
local function updateviewplayer(viewertempid)
    -- skynet.error("updateviewplayer",viewertempid)
    if playerview[viewertempid] == nil then return end
    local myobj = OBJ[viewertempid]
    local mypos = myobj.movement.pos

    -- table.dumpdebug(playerview,"playerview",20)

    --离开他人视野
    local leavelist = {
        playerlist = {},
        monsterlist = {},
    }
    --进入他人视野
    local enterlist = {
        playerlist = {},
        monsterlist = {},
    }
    --通知他人自己移动
    local movelist = {
        playerlist = {},
        monsterlist = {},
    }

    local othertempid
    local otherpos
    local othertype
    local otherobj
    for k, v in pairs(playerview[viewertempid]) do
        assert(OBJ[k], string.format(" watch %s 不存在", tostring(k)))
        othertempid = OBJ[k].tempid
        otherpos = OBJ[k].movement.pos
        othertype = OBJ[k].type
        otherobj = {
            tempid = othertempid,
            agent = OBJ[k].agent,
        }
        local distance = DIST2(mypos, otherpos)
        -- skynet.error("我们之间的距离为:",distance,",k=",k,",viewertempid=",viewertempid)
        -- skynet.error("AOI_RADIS2:",AOI_RADIS2,",LEAVE_AOI_RADIS2=",LEAVE_AOI_RADIS2)
        if distance <= AOI_RADIS2 then
            if not v then
                playerview[viewertempid][k] = true
                if othertype ~= enumtype.CHAR_TYPE_PLAYER then
                    monsterview[k][viewertempid] = true
                    table.insert(enterlist.monsterlist, OBJ[k])
                else
                    playerview[k][viewertempid] = true
                    -- skynet.error("重新进入视野:",distance,",k=",k,",viewertempid=",viewertempid)
                    table.insert(enterlist.playerlist, OBJ[k])
                end
            else
                inserttotablebytype(movelist, otherobj, othertype)
            end
        elseif distance > AOI_RADIS2 and distance <= LEAVE_AOI_RADIS2 then
            if v then
                playerview[viewertempid][k] = false
                if othertype ~= enumtype.CHAR_TYPE_PLAYER then
                    monsterview[k][viewertempid] = false
                    table.insert(leavelist.monsterlist, otherobj)
                else
                    playerview[k][viewertempid] = false
                    table.insert(leavelist.playerlist, otherobj)
                end
            end
        else
            if v then
                inserttotablebytype(leavelist, otherobj, othertype)
            end
            playerview[viewertempid][k] = false

            if othertype ~= enumtype.CHAR_TYPE_PLAYER then
                monsterview[k][viewertempid] = false
            else
                playerview[k][viewertempid] = false
            end
        end
    end

    -- skynet.error("leavelist=",cjson.encode(leavelist))
    --离开他人视野
    for _, v in pairs(leavelist.playerlist) do
        skynet.send(v.agent, "lua", "delaoiobj", viewertempid, "updateviewplayer")
    end

    --重新进入视野
    for _, v in pairs(enterlist.playerlist) do
        skynet.send(v.agent, "lua", "addaoiobj", myobj, "updateviewplayer")
    end

    --视野范围内移动
    for _, v in pairs(movelist.playerlist) do
        skynet.send(v.agent, "lua", "updateaoiobj", myobj)
    end

    --怪物的更新合并一起发送
    if not table.empty(leavelist.monsterlist) or
        not table.empty(enterlist.monsterlist) or
        not table.empty(movelist.monsterlist) then
        local monsterenterlist = {
            obj = myobj,
            monsterlist = enterlist.monsterlist,
        }
        local monsterleavelist = {
            tempid = viewertempid,
            monsterlist = leavelist.monsterlist,
        }
        local monstermovelist = {
            obj = myobj,
            monsterlist = movelist.monsterlist,
        }
        skynet.send(mapagent, "lua", "updateaoiinfo", monsterenterlist, monsterleavelist, monstermovelist)
    end

    --通知自己
    skynet.send(myobj.agent, "lua", "updateaoilist", enterlist, leavelist)
end

--aoi回调
function CMD.aoicallback(w, m)
    -- skynet.error("aoi callback --------------------------> ",",w=",w,",m=",m)
    -- assert(OBJ[w],w)
    -- assert(OBJ[m],m)
    if not OBJ[w] or not OBJ[m] then return end

    w_type = OBJ[w].type
    m_type = OBJ[m].type

    w_tempid = OBJ[w].tempid
    m_tempid = OBJ[m].tempid

    if w_type==enumtype.CHAR_TYPE_MONSTER then
        if monsterview[w_tempid] == nil then
            monsterview[w_tempid] = {}
        end
        monsterview[w_tempid][m_tempid] = true

    elseif w_type==enumtype.CHAR_TYPE_PLAYER then
        if playerview[w_tempid] == nil then
            playerview[w_tempid] = {}
        end
        playerview[w_tempid][m_tempid] = true
    end

    if m_type==enumtype.CHAR_TYPE_MONSTER then
        if monsterview[m_tempid] == nil then
            monsterview[m_tempid] = {}
        end
        monsterview[m_tempid][w_tempid] = true
    elseif m_type==enumtype.CHAR_TYPE_PLAYER then
        if playerview[m_tempid] == nil then
            playerview[m_tempid] = {}
        end
        playerview[m_tempid][w_tempid] = true
    end

    if w_type==enumtype.CHAR_TYPE_PLAYER then
        --通知agent
        skynet.send(OBJ[w].agent, "lua", "addaoiobj", OBJ[m], "aoicallback player:"..m_tempid)
    end

    if OBJ[m].type ~= enumtype.CHAR_TYPE_PLAYER then
        skynet.send(OBJ[m].agent, "lua", "addaoiobj", OBJ[m].tempid, OBJ[w], "aoicallback")
    end
end

-- 添加到aoi
function CMD.enter(obj)
    assert(obj)
    assert(obj.agent)
    assert(obj.movement)
    assert(obj.movement.mode)
    assert(obj.movement.pos.x)
    assert(obj.movement.pos.y)
    assert(obj.movement.pos.z)


    if obj.type == 1 then
        -- skynet.error(string.format("AOI ENTER %d %s %d %d %d",obj.tempid,obj.movement.mode,obj.movement.pos.x,obj.movement.pos.y,obj.movement.pos.z))
    end
    OBJ[obj.tempid] = obj

    if obj.type ~= enumtype.CHAR_TYPE_PLAYER then
        updateviewmonster(obj.tempid)
    else
        updateviewplayer(obj.tempid)
    end

    playerview[obj.tempid] = playerview[obj.tempid] or {}

    local x = math.floor(obj.movement.pos.x / 10)
    local y = math.floor(obj.movement.pos.y / 10)
    local z = math.floor(obj.movement.pos.z / 10)
    assert(pcall(skynet.send, aoi, "text", "update " .. obj.tempid .. " " .. obj.movement.mode .. " " .. x .. " " .. y .. " " .. z))
    need_update = true
end

--从aoi中移除
--TODO 怪物的离开
function CMD.leave(obj)
    assert(obj)
    assert(pcall(skynet.send, aoi, "text", "update " .. obj.tempid .. " d " .. obj.movement.pos.x .. " " .. obj.movement.pos.y .. " " .. obj.movement.pos.z))
    OBJ[obj.tempid] = nil
    skynet.error("aoi leave ====>", obj.tempid)

    if obj.type == enumtype.CHAR_TYPE_PLAYER then
        if playerview[obj.tempid] then
            local monsterleavelist = {
                tempid = obj.tempid,
                monsterlist = {},
            }
            for k, _ in pairs(playerview[obj.tempid]) do
                if playerview[k] then
                    if playerview[k][obj.tempid] then
                        --视野内需要通知
                        skynet.send(OBJ[k].agent, "lua", "delaoiobj", obj.tempid, "leave")
                    end
                    playerview[k][obj.tempid] = nil
                elseif monsterview[k] then
                    if monsterview[k][obj.tempid] then
                        --视野内需要通知
                        table.insert(monsterleavelist.monsterlist, { tempid = k })
                    end
                    monsterview[k][obj.tempid] = nil
                end
            end

            if not table.empty(monsterleavelist.monsterlist) then
                skynet.send(mapagent, "lua", "updateaoiinfo", { monsterlist = {} }, monsterleavelist, { monsterlist = {} })
            end
            playerview[obj.tempid] = nil
        end
    else
        if monsterview[obj.tempid] then
            local monsterleavelist = {
                tempid = obj.tempid,
                monsterlist = {},
            }
            for k, _ in pairs(monsterview[obj.tempid]) do
                skynet.error("leave ",obj.tempid," is watching ",k,type(k))
                if playerview[k] then
                    if playerview[k][obj.tempid] then
                        --视野内需要通知
                        skynet.error("delaoiobj ",obj.tempid)
                        skynet.send(OBJ[k].agent, "lua", "delaoiobj", obj.tempid, "leave")
                    else
                        skynet.error(" ",k," is not watching ",obj.tempid,",playerview[k][obj.tempid]=",tostring(playerview[k][obj.tempid]))
                    end
                    playerview[k][obj.tempid] = nil
                elseif monsterview[k] then
                    if monsterview[k][obj.tempid] then
                        table.insert(monsterleavelist.monsterlist, { tempid = k })
                    end
                    monsterview[k][obj.tempid] = nil
                else
                    skynet.error("leave ", " canot found any ",k)
                end
            end

            skynet.error("leave ", " quit ok")

            if not table.empty(monsterleavelist.monsterlist) then
                skynet.send(mapagent, "lua", "updateaoiinfo", { monsterlist = {} }, monsterleavelist, { monsterlist = {} })
            end
            monsterview[obj.tempid] = nil
        else
            skynet.error(" monster can not found ",obj.tempid)
        end
    end

    need_update = true
end

--0.1秒更新一次
local function message_update()
    if need_update then
        need_update = false
        assert(pcall(skynet.send, aoi, "text", "message "))
    end
    update_thread = skynet.timeout(10, message_update)
end

function CMD.open()
    aoi = assert(skynet.launch("caoi", map_name))
    assert(aoi == (skynet.self() + 1))
    mapagent = skynet.self() - 1
    message_update()
end

function CMD.close(name)
    skynet.error("close aoi(%s)...", name)
    update_thread()
end

skynet.start(function()
    skynet.dispatch("text", function(_, _, cmd)
        -- skynet.error("aoi service",cmd)
        local t = cmd:split(" ")
        local f = CMD[t[1]]
        if f then
            luaqueue(f, tonumber(t[2]), tonumber(t[3]))
        else
            skynet.error("---------->Unknown command : ", cmd)
        end
    end)

    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.ret(skynet.pack(luaqueue(f, ...)))
        else
            skynet.error("Unknown command : [%s]", cmd)
            skynet.response()(false)
        end
    end)
end)

skynet.info_func(function()

    local mqlen = skynet.stat("mqlen")
    local message = skynet.stat("message")
    local cpu = skynet.stat("cpu")
    return {
        mqlen = mqlen,
        message = message,
        cpu = cpu,
    }
end)
