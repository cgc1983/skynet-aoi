socket = require "socket"
math = require "math"
bit = require "bit"

-- 开始时间截 (2015-01-01)
twepoch = 1420041600000
-- 机器id所占的位数
workerIdBits = 5
-- 数据标识id所占的位数
datacenterIdBits = 5
-- 序列在id中占的位数
sequenceBits = 12
-- 支持的最大机器id，结果是31 (这个移位算法可以很快的计算出几位二进制数所能表示的最大十进制数)
maxWorkerId =  bit.lshift(1 , workerIdBits)-1
-- 支持的最大数据标识id，结果是31
maxDatacenterId =  bit.lshift(1 , datacenterIdBits)-1
-- 机器ID向左移12位
workerIdShift = sequenceBits
-- 数据标识id向左移17位(12+5)
datacenterIdShift = sequenceBits + workerIdBits
-- 时间截向左移22位(5+5+12)
timestampLeftShift = sequenceBits + workerIdBits + datacenterIdBits
-- 生成序列的掩码，这里为4095 (0b111111111111=0xfff=4095)
sequenceMask =   bit.lshift(1 , sequenceBits) -1
-- 工作机器ID(0~31)
workerId=1
-- 数据中心ID(0~31)
datacenterId=1
-- 毫秒内序列(0~4095)
sequence = 0
-- 上次生成ID的时间截
lastTimestamp = -1

local _M = {}

function  _M.SnowflakeIdWorker (workerIds, datacenterIds)
    if (workerIds > maxWorkerId or workerIds < 0)
    then
        return -1
    end

    if (datacenterIds > maxDatacenterId or datacenterIds < 0)
    then
        return -1
    end
    workerId=workerIds
    datacenterId=datacenterIds
end

local function tilNextMillis(lastTimestamp)
    local timestamp = math.floor(socket.gettime() * 1000 )
    while (timestamp <= lastTimestamp)
    do
        timestamp = math.floor(socket.gettime() * 1000 )
    end
    return timestamp
end

function  _M.nextId ()
  local timestamp = math.floor(socket.gettime() * 1000 )
  -- 如果当前时间小于上一次ID生成的时间戳，说明系统时钟回退过这个时候应当抛出异常
  if (timestamp < lastTimestamp)
  then
    return -1
  end
  -- 如果是同一时间生成的，则进行毫秒内序列
  if (lastTimestamp == timestamp)
  then
    sequence = bit.band((sequence + 1), sequenceMask)
    -- 毫秒内序列溢出
    if (sequence == 0)
    then
      --阻塞到下一个毫秒,获得新的时间戳
      timestamp = tilNextMillis(lastTimestamp)
    end
  else
     sequence = 0
  end
  lastTimestamp = timestamp
  cmd =("sh ./id.sh " ..  timestamp  .. '\t' ..twepoch .. '\t'.. timestampLeftShift .. '\t'.. datacenterId .. '\t'.. datacenterIdShift .. '\t'.. workerId .. '\t'.. workerIdShift  .. '\t'.. sequence)
  id = os.execute(cmd)
  return id
end

return _M