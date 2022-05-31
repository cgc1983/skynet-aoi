
--全局id生成器
local utilsdate={}

local function onedaybegin(t)
    t = t or os.time()
    local temp1 = os.date('*t',t)
    return os.time({year=temp1.year, month=temp1.month, day=temp1.day, hour=0,min=0,sec=0})
end

function utilsdate.daybegin(t)
    local d = os.date("*t",t)
    local s = string.format("%04d%02d%02d",d.year,d.month,d.day)
    return s
end

function utilsdate.month(t)
    local d = os.date("*t",t)
    local s = string.format("%04d%02d",d.year,d.month)
    return s
end

utilsdate.onedaybegin=onedaybegin

function utilsdate.restyoneday(t)
    local a = onedaybegin(t)
    a=a+24*3600*2
    local expire = a-os.time()
    return expire
end

function utilsdate.onedaybyhourmin(thour,tmin)
    local temp1 = os.date('*t',os.time())
    return os.time({year=temp1.year, month=temp1.month, day=temp1.day, hour=thour,min=tmin,sec=0})
end

return utilsdate
