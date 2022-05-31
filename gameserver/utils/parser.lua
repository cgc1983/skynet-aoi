--模型保存序列化
local cjson = require "cjson"

require "functions"

local parser={}
function parser.getmember(t)
    local temp={}

    for k,v in pairs(t) do
        local mytp=type(v)
        if mytp=='table' then
            temp[k]=mytp
        else
            if mytp~='function' then
                local s,e = string.find(k,'_')
                if not s or s~=1  then
                    temp[k]=mytp
                end
            end
        end
    end

    return temp
end


function parser.getdatatbl(t)
    local temp={}

    for k,v in pairs(t) do
        local mytp=type(v)
        if mytp=='table' then
            temp[k]=v
        else
            if mytp~='function' then
                local s,e = string.find(k,'_')
                if not s or s~=1  then
                    temp[k]=v
                end
            end
        end
    end

    return temp
end

function parser.serialize(t,exceptlist)
    exceptlist=exceptlist or {}
    local d ={}
    for k,v in pairs(t) do
        local tp=type(v)
        local s,e = string.find(k,'_')
        if (not s or s~=1) and tp=='table' and not exceptlist[k] then
                table.insert(d,k)
                table.insert(d,cjson.encode(v))
        else
            if tp~='function' and not exceptlist[k] then
                local s,e = string.find(k,'_')
                if not s or s~=1  then
                    table.insert(d,k)
                    table.insert(d,v)
                end
            end
        end
    end
    return d 
end

function parser.unserialize(t,d)
    for k,v in pairs(t) do
        local tp=type(v)
        if tp=='table' and d[k] then
            local temp1=type(d[k])
            if temp1=="string" then
                t[k]=cjson.decode(d[k])
            elseif temp1=="table" then
                t[k]=d[k]
            else
                error("反序列化数据错误")
            end
        else
            if tp~='function' and d[k]  then
                if tp=="number" then
                    t[k]=tonumber(d[k])
                else
                    t[k]=d[k]
                end
            end
        end
    end

    return t
end


function parser.redis_pack( ... )
    local t = {}
    local s = ...
    for i=1,#s,2 do
        local k = s[i]
        local v = s[i+1]
        t[k] = v
    end

    return t
end


function parser.getpob(t,exceptlist)
    exceptlist=exceptlist or {}
    local temp={}

    for k,v in pairs(t) do
        local mytp=type(v)
        if mytp=='table' and not exceptlist[k] then
            temp[k]=v
        else
            if mytp~='function' then
                local s,e = string.find(k,'_')
                if not s or s~=1 and not exceptlist[k] then
                    temp[k]=v
                end
            end
        end
    end

    return temp
end


function parser.setpob(t,t1,exceptlist)
    exceptlist=exceptlist or {}

    for k,v in pairs(t1) do
        if not exceptlist[k] then
            t[k]=t1[k]
        end
    end

    return t
end

function parser.makedbobj()
    local obj={}
    obj._n=0
    return obj
end

function parser.parse(dbobj)

end

function parser.beginwritedbobj(obj)
    local s=obj._score or 0
    obj._score = s+1
end

function parser.endwritedbobj(obj)
end

function parser.cmppob(pob1,pob2)
    for k, v in pairs( pob1 ) do
        if not pob2[k] or pob2[k]~=v then
            return false
        end
    end
    return true
end


return parser
