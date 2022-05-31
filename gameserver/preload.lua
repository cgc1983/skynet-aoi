-- This file will execute before every lua service start
-- See config
--print("PRELOAD", ...)
PROJ_ROOT="../gameserver"

--配置信息
--
DEBUG      = true
XXTEA_KEY  = "ttxxteakey"

SERVERNAME = "gameserver"  --当前服务名称

-- redis 集群配置
REDIS_CLUSTER={
    {host="127.0.0.1",port=6381},
    {host="127.0.0.1",port=6382},
    {host="127.0.0.1",port=6383},
}

REDIS={
    host="127.0.0.1",
    port=6379,
}

LOGIN_PORT = 8001 --登录端口
GATE_PORT  = 8888 -- 网关端口

collectgarbage()
