-- This file will execute before every lua service start
-- See config
print("PRELOAD", ...)
PROJ_ROOT = "../gameserver"

--配置信息
--
DEBUG    = false
API_IP   = ""
API_PORT = "9080"

XXTEA_KEY = "ttxxteakey"

SERVERNAME = "gameserver"

MY_CLUSTER_IP = ""
MY_IP         = ""
MY_PORT       = 8089
collectgarbage()
