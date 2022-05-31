package.path = package.path..";"..PROJ_ROOT.."/utils/?.lua"..";"..PROJ_ROOT.."/handler/?.lua"..";"..PROJ_ROOT.."/gamelogic/?.lua"..";"

require "functions"
math.randomseed(tostring(os.time()):reverse():sub(1, 6))

local skynet    = require "skynet"
local bc       = require "bc"
local reg      = "[+-]?(%d+%.*%d*)"

local ZHAO   = "1000000000000"
local BCZHAO = bc.number(ZHAO)


local function repeats(s, n) return n > 0 and s .. repeats(s, n-1) or "" end

local converter={}

local function calzhishu(ext)
    assert(type(ext)=='string','type error')
    assert(ext~=nil,"ext not nil")
    local count = string.len(ext)
    -- print('count=',count)
    local index = 2*count

    local c  = string.sub(ext,1,1)
    local b1=string.byte(c)

    if b1>=97 and b1<=122 then
        index = index - 1
    end

    local b1=string.byte(string.lower(string.sub(ext,1,1)))
    -- print("calzhishu index=",index)
    local mi = (index-1)*26+b1-string.byte("a")+1
    -- print("zhishu mi=",mi)
    local v = bc.pow("1000",mi)
    v=v*BCZHAO
    -- v=v/bc.pow("1000",52)
    return v
end

local function caldanwei(x)

    local tmp = tostring(x)
    -- print("tmp=",tmp)
    -- print("tmp=",tmp)
    if true then
        local a,b = string.find(tmp,"%.")
        -- print('a=',a,',b=',b)
        if a~=-1 then
            print("a~=-1")
            tmp = string.sub(tmp,1,a-1)
        end
    end
    -- print("tmp=",tmp)

    local digitallen = string.len(tmp)
    -- print('digitallen=',digitallen)
    if digitallen%3==0 then
        digitallen=digitallen-3
    end
    digitallen=3*math.floor(digitallen/3)
    -- print('digitallen=',digitallen)


    local len1   = math.floor(digitallen/3)
    local group1 = math.ceil(digitallen/52/3)
    local group2 = math.ceil(digitallen/26/3)

    local tmp1 = (len1-1)%26+1
    local ch   = string.byte("a") +tmp1-1
    ch         = string.char(ch)

    local capital =(group2%2)==0
    -- print("capital=",capital)
    -- print("ch=",ch)
    -- print("tmp1=",tmp1)

    if capital then
        ch = string.upper(ch)
    end

    return repeats(ch,group1),string.format("1%s",repeats("0",(group2-1)*26*3+tmp1*3))
end


function converter.str2bc(s)
    -- bc.digits(3)
    -- skynet.error('loaduser u str2bc s===', s)
    if tonumber(s) ~= nil then
         return bc.number(s)
    end
    -- skynet.error('converter str2bc===', s)
    local a,b = string.find(s,reg)
    -- skynet.error('converter str2bc a===', a)
    -- skynet.error('converter str2bc b===', b)
    if not a or a==-1 then
        return bc.number(s)
    end
    assert(a==1,"data format error")
    local val = string.sub(s,a,b)
    -- print('val=',val)
    local danwei
    if b<string.len(s) then
        -- print('b < len1')
        local ext   = string.sub(s,b+1,-1)
        -- print('ext=',ext)
        danwei = calzhishu(ext)
        local tmp = tostring(danwei)
        local a,b = string.find(tmp,"%.")
        --print('a=',a,',b=',b)
        if a and a~=-1 then
            tmp = string.sub(tmp,1,a-1)
        end
        -- print('danwei',danwei)
        --print('tmp',tmp)
        --print("tmp len =",string.len(tmp))
    else
        danwei = bc.number "1"
    end
    local val      = bc.number(val)
    local original = s
    local bcval    = bc.number(val)
    local bcval    = bcval * danwei
    return bcval/bc.pow(1000,52)
end

function converter.bc2str(x)
    -- bc.digits(3)
    --print('x=',x)
    if x<(BCZHAO*1000) then
        return tostring(x)
    end
    x=x*bc.pow(1000,52)
    x=x/BCZHAO
    --print('x=',x)

    local danwei,div = caldanwei(x)

    -- print("sss---danwei=",danwei)
    -- print("sss---div=",div)
    --print("sss-- div len ",string.len(div))
    --print("sss-- x len ",string.len(tostring(x)))

    --print('x=',x)

    local div = bc.number(div)
    local b = x/div
    b=tostring(b)
    b=tonumber(b)
    return string.format("%s%s",tostring(b),danwei)
end

function converter.test(count)

    local chars = {
        'a','b','c','d','e','f','g','h','i','j','k','l','m','n',
        'o','p','q','r','s','t','u','v','w','x','y','z',
    }

    local index = 0
    repeat
        bc.digits(math.floor(math.random(2,8)))
        print(repeats("-",80))
        local r  = math.random(1,#chars)
        local r1 = math.random(1,5)
        local r2 = math.random(2,10)
        local r4 = math.random(101,999)

        local danwei = repeats(chars[r],r2)

        if r1%2==0 then
            danwei = string.upper(danwei)
        end

        local rr = r4/math.random(1,100)
        rr=math.floor(rr*1000)
        rr=rr/1000

        -- bc.digits(3)

        local s0=string.format("%s%s",tostring(rr),danwei)
        print("第",index,'测试')
        s0="178.0zzz"
        print('s0=',s0)
        --s0="63.125ooooo"
        local bn = converter.str2bc(s0)
        print("bn=",bn)
        local s = converter.bc2str(bn)
        print('s=',s)

        --local bn2 = converter.str2bc(s)
        --assert(bn==bn2,"数据错误")
        assert(s==s0,"数据错误")
        index = index + 1

        count=count-1
    until(count<=0)


end


return converter
