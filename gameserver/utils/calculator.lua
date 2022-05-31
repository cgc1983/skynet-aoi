package.path = package.path..";"..PROJ_ROOT.."/utils/?.lua"..";"..PROJ_ROOT.."/handler/?.lua"..";"..PROJ_ROOT.."/gamelogic/?.lua"..";"
local calculator={}


local bc     = require "bc"
local skynet = require "skynet"

math.randomseed(tostring(os.time()):reverse():sub(1, 6))

local function repeats(s, n) return n > 0 and s .. repeats(s, n-1) or "" end

function calculator.callevelprice(base,mi,startlevel, endlevel)
    local x = bc.number(tostring(base))
    local one = bc.number("1")
    local total = x*mi*(one-bc.pow(mi,startlevel - 1))/(one-mi)
    local total1 = x*mi*(one-bc.pow(mi,endlevel - 1))/(one-mi)
    return total1 - total
    -- local x = bc.number(tostring(base))
    -- local one = bc.number("1")

    -- local a0=bc.number(1)
    -- -- local a0=bc.pow(mi,startlevel - 1)
    -- lvl = lvl - 1
    -- repeat
    --     a0=a0*mi
    --     lvl=lvl-1
    -- until(lvl<=0)
    -- local total = x*mi*(one-a0)/(one-mi)
    -- skynet.error('total===', total)
    -- return total
end

function calculator.calmaxlevelprice(base,mi,coin,startlevel,maxlevel)
    -- bc.digits(3)
    local bccoin = bc.number(tostring(coin))
    local s = tonumber(startlevel)
    local e = tonumber(maxlevel or (startlevel + 1000))

    local count

    while true do
        local half = math.floor((s+e)/2) --升到几级
        local total = calculator.callevelprice(base,mi,half-startlevel) --升级需要的金币
        total=bc.number(tostring(total))
        if s==e or half==s or half==e then
            count = s
            break
        end
        if  bccoin<total then
            e=half
        elseif bccoin>total then
            s=half
        else
            count = half
            break
        end
    end

    local n = math.floor(tonumber(tostring(count)))

    return n
end

function calculator.caltupobeishu(tupotime)
    -- bc.digits(4)
    local time = os.time()-tupotime
    skynet.error("calculator caltupobeishu cha time=", time)
    local base = 1
    local n = math.floor(time/10) --衰减几个0.0002 即过了几个10秒
    skynet.error("过了几个10秒 n=", n)
    local t = time%10 --最后一个数的数量
    skynet.error("最后一个数的数量 t=", t)
    local s = 0.0002 * n
    skynet.error("衰减了多少 s=", s)
    local m = (1- 0.4)/0.0002
    skynet.error("衰减到0.4 衰减了多少秒 m=", m)
    local a = bc.number"0"
    local c = 1
    for i=0, n - 1 do
        local d = math.min(i, m)
        c = 1 - (0.0002 * d) --衰减后的数值
        a = a + (c * 10)
    end
    local g = c - 0.0002
    return a+g*t
end

function calculator.test(count)
    local index=1
    local s = os.time()
    repeat
        skynet.error(repeats("-",80))
        skynet.error("第",index,'测试')

        local r = math.random(3,1000)
        skynet.error("r=",r)
        local a  = calculator.callevelprice(5.75,1.15,r-2)
        skynet.error("a=",a)
        --

        local elapsed = os.time() - s

        if elapsed>0 and index%10000==0 then
            skynet.error("qps=",index/elapsed)
        end

        local n = calculator.calmaxlevelprice(5.75,1.15,a,2,r+100)
        skynet.error("count===",n)
        assert(r==tonumber(n),"cal error")
        collectgarbage()
        index = index +1
    until(index>=count)
end


return calculator
