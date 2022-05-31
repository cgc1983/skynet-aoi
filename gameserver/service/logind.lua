--登录服务器
local login      = require "snax.loginserver"
local crypt      = require "skynet.crypt"
local skynet     = require "skynet"

local port = ...
local server = {
    host = "0.0.0.0",
    port = port,
    multilogin = false,	-- disallow multilogin
    name = "login_master",
}

local server_list = {}
local user_online = {}
local user_login = {}

function server.auth_handler(token)
    -- the token is base64(user)@base64(server):base64(password)
    local user, server, password = token:match("([^@]+)@([^:]+):(.+)")

    user = crypt.base64decode(user)
    server = crypt.base64decode(server)
    password = crypt.base64decode(password)

    local ok,ret = pcall(skynet.call,"redisd","lua","checkuser",server,user,password)
    assert(ok,"redisd is error can not callback")
    assert(ret.ok,"验证码错误")
    return server, user
end

function server.login_handler(server, uid, secret)
    skynet.error(string.format("%s@%s is login, secret is %s", uid, server, crypt.hexencode(secret)))
    local gameserver = assert(server_list[server], "Unknown server")

    local last = user_online[uid]
    if last then
        skynet.error(string.format("kick the old user %s",tostring(uid)))
        skynet.call(last.address, "lua", "kick", uid, last.subid)
    end

    skynet.error("check user is online or not")
    if user_online[uid] then
        error(string.format("user %s is already online", uid))
    end

    local subid = tostring(skynet.call(gameserver, "lua", "login", uid, secret))
    user_online[uid] = { address = gameserver, subid = subid , server = server}
    return subid
end

local CMD = {}

function CMD.register_gate(server, address)
    skynet.error(string.format("============ server %s register_gate,address %s",server,tostring(address)))
    server_list[server] = address
end

function CMD.logout(uid, subid)
    skynet.error("logind logout:",tostring(uid))
    local u = user_online[uid]
    if u then
        print(string.format("%s@%s is logout", uid, u.server))
        user_online[uid] = nil
    end
end

function server.command_handler(command, ...)
    local f = assert(CMD[command])
    return f(...)
end

login(server)
