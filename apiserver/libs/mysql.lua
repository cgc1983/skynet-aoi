local mysql = require "resty.mysql"
local cjson = require "cjson"
local string = require "string"
-- local config = {
--     host = "127.0.0.1",
--     port = 3306,
--     database = "mr_database",
--     user = "root",
--     password = "root",
--     charset = "utf8"
-- }

local _M = {}


local function on_connect(db)
    db:query("set charset utf8mb4");
end


local function close(self)
    ngx.log(ngx.DEBUG,"close db=====>")
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end
    if self.subscribed then
        return nil, "subscribed state"
    end
    return sock:setkeepalive(10000, 50)
end



function _M.new(self,cnf)
    local db, err = mysql:new()
    if not db then
        ngx.log(ngx.INFO,"db is err")
        return nil
    else
        ngx.log(ngx.INFO,"db is ok")
    end
    db:set_timeout(1000) -- 1 sec

    local ok, err, errno, sqlstate = db:connect{
    host = cnf.ip,
    port = cnf.port,
    database = cnf.db,
    user = cnf.user,
    password = cnf.password,
    charset = "utf8mb4",
    max_packet_size = 1024 * 1024,
    on_connect = on_connect
    }

    if not ok then
        return nil
    end
    db.close = close
    return db
end


return _M