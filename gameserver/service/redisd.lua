-- redis db保存类，稍后可以尝试支持集群
local skynet = require "skynet"
local cjson = require "cjson"
local redis = require 'skynet.db.redis'
local parser = require "parser"
local rediscli

require "skynet.manager"


local CMD = {}

function CMD.checkuser(server,user,code)
    local k = string.format("%s:%s",server,user)

    --测试代码，这部分需要去redis验证一下,验证码
    if code~="123456" then
        return {
            ok=false,
        }
    end

    local id = rediscli:get(k)
    if not id then
        id = rediscli:incrby("user_id",1)
        rediscli:set(k,id)
    end

    return {
        ok=true,
        id=id,
    }
end

function CMD.loadid(server,user)
    local k = string.format("%s:%s",server,user)
    local id = rediscli:get(k)
    return id
end

function CMD.loaduser(id)
    assert(id,"用户ID不能是空")
    local ok,val = pcall(tonumber,id)
    assert(ok,"用户ID不能是空")
    assert(val>0,"用户ID不能是空")

    local k = string.format("user:%s",tostring(id))
    local data = rediscli:hgetall(k)
    --从redis里面读出的数据不是hash map格式的需要变成map
    local t= parser.redis_pack(data)
    return t
end

function CMD.saveuser(id,user_data)
    assert(id,"用户ID不能是空")
    local ok,val = pcall(tonumber,id)
    assert(ok,"用户ID不能是空")
    assert(val>0,"用户ID不能是空")

    local k = string.format("user:%s",tostring(id))
    rediscli:hmset(k,table.unpack(user_data))
    return "ok"
end

function CMD.clearmonster()
    rediscli:set("monster",0)
    return "ok"
end


function CMD.incmonster(c)
    rediscli:incrby("monster",c)
    return "ok"
end


skynet.start(function()
    rediscli = redis.connect(REDIS)
    rediscli:setnx("user_id",1000000)

    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command])
        local ret = f(...)

        if ret then
            skynet.ret(skynet.pack(ret))
        end

    end)
    collectgarbage()

    skynet.register "redisd"
end)
