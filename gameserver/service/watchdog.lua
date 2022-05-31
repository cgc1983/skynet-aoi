package.path = package.path..";"..PROJ_ROOT.."/utils/?.lua"..";"..PROJ_ROOT.."/handler/?.lua"..";"..PROJ_ROOT.."/gamelogic/?.lua"..";"

local skynet   = require "skynet"
local crypt    = require "skynet.crypt"
local cjson    = require "cjson"
local crypt    = require "skynet.crypt"
local cmsgpack = require "cmsgpack"

local name,loginservice=...


local CMD     = {}
local SOCKET  = {}
local gate
local agent = {}

local user_online ={}
local user_secret = {}
local session_map = {}

local subid=0
local OPEN_SECRET=false

local proxy


local function get_user_by_session(fd)
    for k,v in pairs(session_map) do
        if k == fd then
            return v.userid
        end
    end
end

local function get_fd_by_userid(userid)
    for k,v in pairs(session_map) do
        if v.userid == userid then
            return k
        end
    end
end



function SOCKET.open(fd, addr)
    skynet.error("New client from : " .. addr)
    -- agent[fd] = skynet.newservice("agent")
    -- skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
    skynet.call(gate, "lua", "accept", fd)
end

local function close_agent(fd)
    skynet.error("close agent fd=",fd)

    session_map[fd]=nil

    local a = agent[fd]
    agent[fd] = nil
    if a then
        skynet.call(gate, "lua", "kick", fd)
        -- disconnect never return
        skynet.send(a, "lua", "disconnect")
    end
end

function SOCKET.close(fd)
    skynet.error("socket close",fd)
    close_agent(fd)
end

function SOCKET.error(fd, msg)
    skynet.error("socket error",fd, msg)
    close_agent(fd)
end

function SOCKET.warning(fd, size)
    -- size K bytes havn't send out in fd
    skynet.error("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
    skynet.error("=========> watchdog socket data",fd, msg)
    -- local ok, cmd = pcall(cjson.decode, msg)
    local ok, cmd = pcall(cmsgpack.unpack, msg)

    if not ok then
        skynet.error("命令数据错误")
        pcall(skynet.call, gate, "lua","kick",fd)
        return
    end

    local data      = cmd.data
    skynet.error(" login data----->", cjson.encode(data))

    local id     = data.id
    local subid  = data.subid
    local token = data.token

    if not id or not subid or not token then
        skynet.error("命令数据错误")
        pcall(skynet.call, gate, "lua","kick",fd)
        return
    end

    local secret_info = user_secret[id]

    local handshake = string.format("%s@%s#%s", crypt.base64encode(id), crypt.base64encode(name),crypt.base64encode(subid))
    local hmac = crypt.hmac64(crypt.hashkey(handshake), secret_info.secret)
    skynet.error("hmac=",hmac)
    if crypt.base64encode(hmac)~=token then
        skynet.error("token 数据错误")
        pcall(skynet.call, gate, "lua","kick",fd)
        return
    end

    skynet.error(string.format("用户登录%s, %s成功!!!!!",tostring(id),tostring(subid)))

    session_map[fd]={fd=fd,userid=id,subid=subid,}

    --创建一个agent
    agent[fd] = skynet.newservice("agent")
    skynet.call(agent[fd], "lua", "start", {
        server=name,
        gate = gate,
        client = fd,
        watchdog = skynet.self(),
        uid=id,
    })
end

function CMD.start(conf)
    skynet.call(gate, "lua", "open" , conf)
    skynet.call(loginservice, "lua", "register_gate",name, skynet.self())
end

function CMD.close(fd)
    skynet.error("关闭 fd:",fd)
    close_agent(fd)
end


function CMD.login(uid,secret)
    -- you may use secret to make a encrypted data stream
    skynet.error("uid=",uid,",secret=",secret)
    skynet.error(string.format("%s is login  secret is %s", uid,crypt.hexencode(secret)))
    -- userid = uid
    -- you may load user data from database

    subid=subid+1
    user_secret[uid]={secret=secret,subid=subid,}
    return subid
end


function CMD.kick( uid, last_subid )

    local ok = pcall(skynet.call,loginservice,'lua','logout',uid,last_subid)
    user_secret[uid]=nil

    local fd = get_fd_by_userid(uid)
    if fd then
        skynet.error("关闭之前登录用户得链接")
        close_agent(fd)
    end
    user_online[uid] =nil

    skynet.error("kick over")
end




skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
        if cmd == "socket" then
            skynet.error("watchdog socket subcmd = ", subcmd)
            local f = SOCKET[subcmd]
            f(...)
            -- socket api don't need return
        else
            skynet.error("watchdog cmd = ", cmd)
            local f = assert(CMD[cmd])
            skynet.ret(skynet.pack(f(subcmd, ...)))
        end
    end)

    gate = skynet.newservice("gate")
end)
