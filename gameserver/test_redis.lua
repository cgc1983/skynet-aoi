local skynet = require "skynet"
local rediscluster = require "skynet.db.redis.cluster"

-- subscribe mode's callback
local function onmessage(data,channel,pchannel)
    print("onmessage",data,channel,pchannel)
end

skynet.start(function ()
    local db = rediscluster.new(REDIS_CLUSTER,
    {read_slave=true,auth="123456",db=0,},
    onmessage
    )

    for i=1,1000 do

        db:del("a")
        db:set("a","a")
        local a = db:get("a")
        assert(a)

        db:del("b")
        db:set("b","b")
        local b = db:get("b")
        assert(b)

        db:del("c")
        db:set("c","c")
        local c = db:get("c")
        assert(c)

        db:del("d")
        db:set("d","d")
        local d = db:get("d")
        assert(d)
    end

    print("test redis cluster complete")
    skynet.exit()
end)
