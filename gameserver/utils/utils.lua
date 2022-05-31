local utils={}

function utils.trantime(time)
    local rtime    = os.date("%m-%d %H:%M",time)
    local c = os.time() - time
    if c <= 60 then
        return '刚刚'
    elseif c <= 60 * 60 then
        local min = math.floor(c/60)
        return string.format("%s分钟前", tostring(min))
    elseif c <= 60 * 60 * 24 then
        local min = math.floor(c/60/60)
        return string.format("%s小时前", tostring(min))
    elseif c <= 60 * 60 * 24 * 7 then
        local min = math.floor(c/60/60/24)
        return string.format("%s天前", tostring(min))
    elseif c <= 60 * 60 * 24 * 30 then
        local min = math.floor(c/60/60/24/7)
        return string.format("%s周前", tostring(min))
    else
        return rtime
    end
end

-- 计算两个时间相差多少天
function utils.calday(t1,t2)
    local d1 = os.date("*t",t1)
    local d2 = os.date("*t",t2)

    local e1 = os.time({year=d1.year, month=d1.month, day=d1.day, hour=0,min=0,sec=0})
    local e2 = os.time({year=d2.year, month=d2.month, day=d2.day, hour=0,min=0,sec=0})

    local e = e2-e1
    e=math.abs(e)
    local day,_,_,_=utils.caldatetime(e)
    return day
end

-- 计算当前时间的今天的开始时间
function utils.onedaybegin(t)
    local temp1 = os.date('*t',t)
    return os.time({year=temp1.year, month=temp1.month, day=temp1.day, hour=0,min=0,sec=0})
end

function utils.getwday(t)
    local d1 = os.date("*t",t)
    return d1.wday
end

function utils.oneweekbegin(t)
    local s=utils.onedaybegin(t)
    local temp1 = os.date('*t',t)
    local index=2
    if temp1.wday==1 then
        index=8
    else
        index=temp1.wday
    end

    return s-(index-2)*24*3600
end

function utils.oneweekend(t)
    local s=utils.onedaybegin(t)
    local temp1 = os.date('*t',t)
    local index=2
    if temp1.wday==1 then
        index=8
    else
        index=temp1.wday
    end

    return s+(8-index)*24*3600+(24*3600-1)
end



function utils.getYearBeginDayOfWeek(tm)
  local yearBegin = os.time{year=os.date("*t",tm).year,month=1,day=1}
  local yearBeginDayOfWeek = tonumber(os.date("%w",yearBegin))
  -- sunday correct from 0 -> 7
  if(yearBeginDayOfWeek == 0) then yearBeginDayOfWeek = 7 end
  return yearBeginDayOfWeek
end

function utils.getDayAdd(tm)
  local yearBeginDayOfWeek = utils.getYearBeginDayOfWeek(tm)
  local dayAdd
  if(yearBeginDayOfWeek < 5 ) then
    -- first day is week 1
    dayAdd = (yearBeginDayOfWeek - 2)
  else
    -- first day is week 52 or 53
    dayAdd = (yearBeginDayOfWeek - 9)
  end
  return dayAdd
end

function utils.getyear(t)
    local temp1 = os.date('*t',t)
    return temp1.year
end

function utils.getmonth(t)
    local temp1 = os.date('*t',t)
    return temp1.month
end

function utils.getWeekNumberOfYear(tm)
  local dayOfYear = os.date("%j",tm)
  local dayAdd = utils.getDayAdd(tm)
  local dayOfYearCorrected = dayOfYear + dayAdd
  if(dayOfYearCorrected < 0) then
    -- week of last year - decide if 52 or 53
    lastYearBegin = os.time{year=os.date("*t",tm).year-1,month=1,day=1}
    lastYearEnd = os.time{year=os.date("*t",tm).year-1,month=12,day=31}
    dayAdd = utils.getDayAdd(lastYearBegin)
    dayOfYear = dayOfYear + os.date("%j",lastYearEnd)
    dayOfYearCorrected = dayOfYear + dayAdd
  end
  local weekNum = math.floor((dayOfYearCorrected) / 7) + 1
  if( (dayOfYearCorrected > 0) and weekNum == 53) then
    -- check if it is not considered as part of week 1 of next year
    local nextYearBegin = os.time{year=os.date("*t",tm).year+1,month=1,day=1}
    local yearBeginDayOfWeek = utils.getYearBeginDayOfWeek(nextYearBegin)
    if(yearBeginDayOfWeek < 5 ) then
      weekNum = 1
    end
  end
  return weekNum
end


function utils.onedayhms(t,h,m,s)
    local temp1 = os.date('*t',t)
    return os.time({year=temp1.year, month=temp1.month, day=temp1.day, hour=h,min=m,sec=s})
end

function utils.onedaybeforebegin(t,d)
    local temp1 = os.date('*t',t)
    local temp= os.time({year=temp1.year, month=temp1.month, day=temp1.day, hour=0,min=0,sec=0})
    temp=temp-d*24*3600
    return temp
end


function utils.onedayboforehms(t,d,h,m,s)
    local temp1 = os.date('*t',t)
    local temp= os.time({year=temp1.year, month=temp1.month, day=temp1.day, hour=h,min=m,sec=s})
    temp=temp-d*24*3600
    return temp
end

function utils.mydump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local traceback = string.split(debug.traceback("", 2), "\n")
    if LOG then
        skynet.error("dump from: " .. string.trim(traceback[3]))
    else
        print("dump from: " .. string.trim(traceback[3]))
    end

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))
        elseif lookupTable[value] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, desciption, spc)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, desciption)
            else
                result[#result +1 ] = string.format("%s%s = {", indent, _v(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _v(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        if LOG then
            skynet.error(line)
        else
            print(line)
        end
    end
end

function utils.get_days_in_month(mnth, yr)
  return os.date('*t',os.time{year=yr,month=mnth+1,day=0})['day']
end

function utils.firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end
-- 快速查找算法
function utils.newset()
    local reverse = {} --以数据为key，数据在set中的位置为value
    local set = {} --一个数组，其中的value就是要管理的数据
    return setmetatable(set,{__index = {
          insert = function(set,value)
              if not reverse[value] then
                    table.insert(set,value)
                    reverse[value] = #set
              end
          end,

          remove = function(set,value)
              local index = reverse[value]
              if index then
                    reverse[value] = nil
                    local top = table.remove(set) --删除数组中最后一个元素
                    if top ~= value then
                        --若不是要删除的值，则替换它
                        reverse[top] = index
                        set[index] = top
                    end
              end
          end,

          find = function(set,value)
              local index = reverse[value]
              return (index and true or false)
          end,
          findindex = function(set,value)
              local index = reverse[value]
              return index
          end,
    }})
end

function utils.rshift(a,n)
    return a<<n
end

function utils.aor(a,b)
    return a|b
end

-- Compute the difference in seconds between local time and UTC.
local function get_timezone()
  local now = os.time()
  return os.difftime(now, os.time(os.date("!*t", now)))
end

function utils.get_timezone()
    return get_timezone()
end

-- Return a timezone string in ISO 8601:2000 standard form (+hhmm or -hhmm)
local function get_tzoffset(timezone)
  local h, m = math.modf(timezone / 3600)
  return string.format("%+.4d", 100 * h + 60 * m)
end



function utils.get_tzoffset(timezone)
    return get_tzoffset(timezone)
end


-- return the timezone offset in seconds, as it was on the time given by ts
-- Eric Feliksik
local function get_timezone_offset(ts)
    local utcdate   = os.date("!*t", ts)
    local localdate = os.date("*t", ts)
    localdate.isdst = false -- this is the trick
    return os.difftime(os.time(localdate), os.time(utcdate))
end


function utils.get_timezone_offset(ts)
    return get_timezone_offset(ts)
end

return utils
