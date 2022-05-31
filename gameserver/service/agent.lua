-- package.path = package.path..";"..PROJ_ROOT.."/utils/?.lua"..";"..PROJ_ROOT.."/?.lua"..";"

local skynet     = require "skynet"
local socket     = require "skynet.socket"
local netpack    = require "skynet.netpack"
local cjson      = require "cjson"
local datacenter = require "skynet.datacenter"
local config     = require "config"
local cmsgpack   = require "cmsgpack"
local usermodel = require "model.user.usermodel"

-- math.randomseed(tostring(os.time()):reverse():sub(1, 7))

require "functions"

local WATCHDOG
local host

local CMD = {}
local roomid
local uid
local client_fd

local runfork = true
local idletime

local funcs={}


local handlers = {
    "game.user.user",
    "game.misc.heartbeat",
    "game.scene.mainscene",
}

local function send_package(pack)

    if not client_fd then
        return
    end

    local data = pack.data
    data.errcode = data.errcode or 0
    if data and data.errcode and data.errcode>0 and not data.errmsg then
        data.errmsg = config.get("errmsg",string.format("e%d",data.errcode))
    end
    -- skynet.error("<=========== agent发送消息:",cjson.encode(pack))
    socket.write(client_fd,netpack.pack(cmsgpack.pack(pack)))
end

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = function (msg, sz)
        local a= skynet.tostring(msg,sz)
        -- return funpack(a)
        return a
    end,
    dispatch = function (fd, _, msg)
        skynet.ignoreret()
        -- skynet.error("agent收到消息===>",msg)
        local ok,cmd = pcall(cmsgpack.unpack, msg)
        if ok then
            idletime = os.time()

            local c = cmd.c
            local m = cmd.m

            local fname = string.format("on_%s_%s",tostring(c),tostring(m))

            local f  = funcs[fname]
            if f then
                local result = f(cmd)
                if result then
                    send_package(result)
                end
            end
        end
    end
}

function CMD.start(conf)

    skynet.error("agent start")

    local fd   = conf.client
    local gate = conf.gate
    WATCHDOG   = conf.watchdog
    client_fd  = fd
    CLIENT_FD  = client_fd

    local id = skynet.call("redisd","lua","loadid",conf.server,conf.uid)
    uid        = math.floor(tonumber(id))
    UID        = uid

    skynet.call(gate, "lua", "forward", fd)
    skynet.error("server agent forward")


    usermodel:load()

    for _,v in ipairs(handlers) do
        local handler = require(v)

        if handler then
            for k,func in pairs(handler) do
                if type(func)=='function' and not string.startwith(k,"_") then
                    local splits = string.split(v,".")
                    local funname=string.format("on_%s_%s",splits[#splits],k)
                    funcs[funname]=func
                end
            end
        end
    end

    idletime = os.time()

    --是否开启心跳检查
    if true then
        --前端定时心跳检测
        skynet.fork(function()
            while runfork do
                if os.time()-idletime>60 then
                    pcall(skynet.send,WATCHDOG,"lua","close",client_fd)
                    break
                end
                if os.time()-idletime >= 60 then
                    collectgarbage()
                end
                skynet.sleep(400)
            end
        end)
    end

    send_package({c="user",m="login",data={errcode=0,}})
    return "ok"
end


function CMD.disconnect()
    skynet.error("disconnect close------>")
    skynet.call(WATCHDOG, "lua", "close", client_fd)

    local ok = pcall(skynet.call,GAME_SCENE["main-scene"],"lua","leave",{
        tempid=UID,
        agent=skynet.self(),
        movement={
            mode="wm",
            pos=POS,
        },
        type=1,
    })

    usermodel:save()

    runfork=false
    skynet.exit()
end

function CMD.updateaoiobj(obj)
    -- skynet.error("aoi agent function updateaoiobj=","my id=",UID,",my post=",cjson.encode(POS),obj.tempid,",data=",cjson.encode(obj))
    send_package({c="aoi",m="updateaoiobj",data={errcode=0,obj=obj,}})
end

function CMD.delaoiobj(tempid,reason)
    -- skynet.error("aoi agent function delaoiobj=","my id=",UID,",my post=",cjson.encode(POS),",tempid=",tempid)
    send_package({c="aoi",m="delaoiobj",data={errcode=0,tempid=tempid,reason=reason,}})
end

function CMD.addaoiobj(obj,reason)
    -- skynet.error("aoi agent function addaoiobj=","my id=",UID,",my post=",cjson.encode(POS),obj.tempid,",data=",cjson.encode(obj))
    send_package({c="aoi",m="addaoiobj",data={errcode=0,obj=obj,reason=reason,}})
end

function CMD.updateaoilist(enterlist,leavelist)
    -- skynet.error("aoi agent function updateaoilist",obj.tempid,",data=",cjson.encode(obj))
    local enter_player_list = enterlist.playerlist
    local enter_monster_list = enterlist.monsterlist

    local leave_player_list = leavelist.playerlist
    local leave_monster_list = leavelist.monsterlist
    if #enter_player_list>0 or #enter_monster_list>0 or #leave_player_list>0 or #leave_monster_list>0 then
        send_package({c="aoi",m="updateaoilist",data={errcode=0,enterlist=enterlist,leavelist=leavelist}})
    end
end



skynet.start(function()
    GAME_SCENE={}

    local secenes={
        "main-scene",
    }

    for _,v in ipairs(secenes) do
        GAME_SCENE[v] = datacenter.get(v)
    end

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
