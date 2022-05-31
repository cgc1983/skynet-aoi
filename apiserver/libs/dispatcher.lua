-- 消息分发模块
-- jack
-- 2017-06-20
--
local semaphore   = require "ngx.semaphore"
local _M          = { _VERSION = '0.01' }
local mt          = {__index = _M}
local workerId    = ngx.worker.id()
local cjson       = require "cjson"
local mask        = 2^32
local server_mask = 2^38
local redis       = require "redis"
local util        = require "utils"
local cmsgpack    = require "cmsgpack"
local global      = require "global"
local SERVER_ID   = global.server_id

local workercount = ngx.worker.count()

require "functions"


local messageList = {}
local incrId      = 0
local smd         = ngx.shared.msgqueue
local semaMap     = {}

local function getWorkerId(sessionId)
    return math.floor(tonumber(sessionId%server_mask)/mask)
end

local function getServerId(sessionId)
    return math.floor(tonumber(sessionId)/server_mask)
end

_M.getWorkerId = getWorkerId
_M.getServerId = getServerId

function _M.dispatchToAll(message)
    for sessionId,v in pairs(messageList) do
        table.insert(v,message)
        _M.wakeUp(sessionId)
    end
end

function _M.dispatchToSession(sessionId,message)
    if ( messageList[sessionId] ~= nil ) then
        table.insert(messageList[sessionId],message)
        _M.wakeUp(sessionId)
    end
end

function _M.getSessionId()
    local sessionId = SERVER_ID*server_mask+workerId * mask + incrId
    incrId = incrId + 1
    incrId=incrId%mask
    messageList[sessionId] = {}

    local sId = getServerId(sessionId)
    local wId = getWorkerId(sessionId)

    return sessionId
end

function _M.getSemaphore(sessionId)
    if ( semaMap[sessionId] == nil ) then
        semaMap[sessionId] = semaphore.new(0)
    end
    return semaMap[sessionId]
end


function _M.wakeUp(sessionId)
    if ( semaMap[sessionId] ~= nil ) then
        -- ngx.log(ngx.INFO,"wake up:",sessionId)
        semaMap[sessionId]:post(1)
    end
end


function _M.dispatch(sessionId,message)
    local sId = getServerId(sessionId)
    local wId = getWorkerId(sessionId)

    if sId==SERVER_ID then
        if wId == workerId then
           _M.dispatchToSession(sessionId,message)
        else
            local k = string.format("msgqueue-%d",wId)
            local len,err=smd:lpush(k,cjson.encode({sessionid=sessionId,message=message}))
        end
    else
        ngx.log(ngx.ERR,"消息分发错误")
    end
end

function  _M.dispathToAllWorker(roomid,message)
    for i=0,workercount-1 do
        local k = string.format("msgqueue-%d",i)
        local len,err=smd:lpush(k,cjson.encode({roomid=roomid,message=message}))
    end
end

function _M.addMessage(sessionId,message)
    local sId = getServerId(sessionId)
    local wId = getWorkerId(sessionId)

    if sId==SERVER_ID then
        if wId == workerId then
            if ( messageList[sessionId] ~= nil ) then
                table.insert(messageList[sessionId],message)
                return true
            end
        else
            local k = string.format("msgqueue-%d",wId)
            local len,err=smd:lpush(k,cjson.encode({sessionid=sessionId,message=message}))
        end
    else
    end
end



---
-- 销毁会话
function _M.destory(sessionId)

    messageList[sessionId] = nil
    semaMap[sessionId]     = nil

end

---
-- 根据会话ID获取消息
--
function _M.getMessage(sessionId)

    if ( messageList[sessionId] ~= nil ) then
        local messages = {}
        table.foreach(messageList[sessionId],
            function(i, v)
                table.insert(messages,v)
                messageList[sessionId][i] = nil
            end
        )
        return messages
    end

end

return _M

