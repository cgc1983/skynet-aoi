package.path = package.path..";"..PROJ_ROOT.."/utils/?.lua"..";"..PROJ_ROOT.."/handler/?.lua"..";"..PROJ_ROOT.."/gamelogic/?.lua"..";"
local skynet = require "skynet"
local mongo = require "skynet.db.mongo"

local _M = {}

function _M.connect(conf)
    return mongo.client(
        {
            host = conf.ip, port = conf.port,
        }
    )
end

return _M