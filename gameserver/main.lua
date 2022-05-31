package.path = package.path..";"..PROJ_ROOT.."/utils/?.lua;"..PROJ_ROOT.."/?.lua;"..PROJ_ROOT.."/service/?.lua;"

local skynet     = require "skynet"
local cjson      = require "cjson"
local datacenter = require "skynet.datacenter"
local max_client = 60000
local crypt      = require "client.crypt"

require "functions"


skynet.start(function()
    skynet.error("启动登录服务器")
    local  redisd = skynet.newservice("redisd")
    datacenter.set("redisd",redisd)

    skynet.call(redisd,"lua","clearmonster")

     if not skynet.getenv "daemon" then
         local console = skynet.newservice("console")
     end
     skynet.newservice("debug_console",8000)

    skynet.newservice("mapagent")
    local  aoi = skynet.newservice("aoi","main")
    skynet.call(aoi,"lua","open")
    datacenter.set("main-scene",aoi)

    -- 登录服务
    local loginserver = skynet.newservice("logind",LOGIN_PORT)

    local watchdog = skynet.newservice("watchdog","sample",loginserver)
    skynet.call(watchdog, "lua", "start", {
        port = GATE_PORT,
        maxclient = max_client,
        nodelay = true,
    })

    skynet.exit()
end)
