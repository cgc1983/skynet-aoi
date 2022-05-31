--工具类
--

local cjson = require "cjson"
local utils={}
require "functions"
local function repeats(s, n) return n > 0 and s .. repeats(s, n-1) or "" end

local packtype = "json"

function utils.msgpack(cmd)
    if packtype == "json" then
        return  cjson.encode(cmd)
    end
    return cmsgpack.pack(cmd)
end

function utils.msgunpack(cmd)
    if packtype == "json" then
        return  cjson.decode(cmd)
    end
    return cmsgpack.unpack(cmd)
end


--redis的对象解压缩
function utils.redis_pack(...)
    local t = {}
    local s = ...
    for i=1,#s,2 do
        local k = s[i]
        local v = s[i+1]
        t[k] = v
    end

    return t
end

function utils.pack(cmd)
    local s = ""
    local l = string.len(cmd)
    local l = utils.int_to_bytes(l,'big', true)
    for i=2,1,-1 do
        if l[i] then
            s=string.format("%s%s", s, string.char(l[i]))
        else
            s=string.format("%s%s", s, string.char(0))
        end
    end
    s=string.format("%s%s", s, cmd)
    return s
end

function utils.packjson(d)
    local s = cjson.encode(d)
    return utils.pack(s)
end

local function table2linekey(parent,tbl,result)
    parent = parent or ""
    for k,v in pairs(tbl) do
        if type(v)=='table' then
            local p = nil
            if parent=='' then
                p = string.format("%s",tostring(k))
            else
                p = string.format("%s.%s",parent,tostring(k))
            end
            table2linekey(p,v,result)
        else
            local p = nil
            if parent=='' then
                p = string.format("%s",tostring(k))
            else
                p = string.format("%s.%s",parent,tostring(k))
            end
            -- local key =string.format("%s.%s",p,tostring(k))
            result[p]=v
        end
    end
end

function utils.table2line(tbl)
    local result = {}
    table2linekey("",tbl,result)
    return result
end

function utils.redis_unpack(values)
    local fields = {}
    for k,v in pairs(values) do
        table.insert(fields,k)
        table.insert(fields,v)
    end
    return fields
end

function utils.getDayByYearMonth(_year, _month)
    local _curYear = tonumber(_year)
    local _curMonth = tonumber(_month)
    if not _curYear or _curYear <= 0 or not _curMonth or _curMonth <= 0 then
        return
    end
    local _curDate = {}
    _curDate.year = _curYear
    _curDate.month = _curMonth + 1
    _curDate.day = 0
    local _maxDay = os.date("%d",os.time(_curDate))
    return _maxDay
end

function utils.safe2number(v)
    local ok,val = pcall(tonumber,v or "y")
    if not val then
        return false
    end
    return ok,val
end

local function convertbonuskey2table(key)
    local arr =  string.split(key,":")
    local arr1 = string.split(arr[1],'-')

    --转换格式
    local reqtime = arr1[1]
    reqtime       = tonumber(reqtime)
    local uid     = arr1[2]
    uid           = tonumber(uid)
    local mine    = arr1[3]
    mine          = tonumber(mine)

    return {
        uid=uid,
        reqtime=reqtime,
        mine=mine,
        bonusid=key,
    }
end

function utils.convertbonuskey2table(key)
    local ok,tbl = pcall(convertbonuskey2table,key)
    return ok,tbl
end

function utils.isprivateip(current_remote_addr)
    local ip_decimal = 0
    local postion = 3
    for i in string.gmatch(current_remote_addr, [[%d+]]) do
        ip_decimal = ip_decimal + math.pow(256, postion) * i
        postion = postion - 1
    end

    if ip_decimal >= 0x7f000000 and ip_decimal <= 0x7fffffff or -- 127.0.0.0 ~ 127.255.255.255
        ip_decimal >= 0x0a000000 and ip_decimal <= 0x0affffff or -- 10.0.0.0 ~ 10.255.255.255
        ip_decimal >= 0xac100000 and ip_decimal <= 0xac1fffff or -- 172.16.0.0 ~ 172.31.255.255
        ip_decimal >= 0xc0a80000 and ip_decimal <= 0xc0a8ffff then   -- 192.168.0.0 ~ 192.168.255.255
        return true
    else
        return false
    end
end

function utils.bytes_to_int(str,endian,signed) -- use length of string to determine 8,16,32,64 bits
    local t={str:byte(1,-1)}
    if endian=="big" then --reverse bytes
        local tt={}
        for k=1,#t do
            tt[#t-k+1]=t[k]
        end
        t=tt
    end
    local n=0
    for k=1,#t do
        n=n+t[k]*2^((k-1)*8)
    end
    if signed then
        n = (n > 2^(#t-1) -1) and (n - 2^#t) or n -- if last bit set, negative.
    end
    return n
end

function utils.int_to_bytes(num,endian,signed)
    if num<0 and not signed then num=-num print"warning, dropping sign from number converting to unsigned" end
    local res={}
    local n = math.ceil(select(2,math.frexp(num))/8) -- number of bytes to be used.
    if signed and num < 0 then
        num = num + 2^n
    end
    for k=n,1,-1 do -- 256 = 2^8 bits per char.
        local mul=2^(8*(k-1))
        res[k]=math.floor(num/mul)
        num=num-res[k]*mul
    end
    assert(num==0)
    if endian == "small" then
        local t={}
        for k=1,n do
            t[k]=res[n-k+1]
        end
        res=t
    end
    return res
end



function utils.encode(cmd)
    local s=string.char(0x02)
    local d = utils.msgpack(cmd)
    local l = string.len(d)
    local l =utils.int_to_bytes(l,'big', true)
    for i=4,1,-1 do
        if l[i] then
            s=string.format("%s%s", s, string.char(l[i]))
        else
            s=string.format("%s%s", s, string.char(0))
        end
    end

    s=string.format("%s%s", s, d)
    s=string.format("%s%s", s, string.char(0x01))
    s=string.format("%s%s", s, string.char(0x02))
    s=string.format("%s%s", s, string.char(0x03))
    return s
end

function utils.cmdlen(data, s, e)
    local datalen = string.sub(data, s, e)
    local len = utils.bytes_to_int(datalen,'big')
    return len
end

return utils
