-- 用户数据模型
local parser = require "parser"
local skynet = require "skynet"
local cjson  = require "cjson"

require "functions"

local usermodel={}

local function init(single)
    single.id=UID
    single.name = string.format("user_%s",tostring(UID))
end

function usermodel.load(self)
    local userdata = skynet.call("redisd","lua","loaduser",UID)
    if #table.keys(userdata)<=0 then
        init(self)
    else
        for k,v in pairs(userdata) do
            self[k]=v
        end
    end

    self._init_ok=true
end

function usermodel.save(self)
    if self._init_ok then
       local user_data=parser.serialize(self)
       skynet.error("usermodel save",cjson.encode(user_data))
       skynet.call("redisd","lua","saveuser",UID,user_data)
   end
end

return usermodel
