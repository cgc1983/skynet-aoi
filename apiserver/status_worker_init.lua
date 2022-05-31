local cjson  = require "cjson"
local redis  = require "redis"
local center = require "center"
local global = require "global"
local utils  = require "utils"
local toml   = require "toml"

ngx.log(ngx.INFO,"worker init")
local workerId = ngx.worker.id()

global.sock_close=false

local config = nil

DEBUG=nil

local function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

local function read_file(path)
    local file = io.open(path, "r") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end
if file_exists("../config/dev.toml") then
    DEBUG = true
    local content = read_file("../config/dev.toml")
    config=toml.parse(content)
else
    local content = read_file("../config/prod.toml")
    config=toml.parse(content)
end
local my_cache = ngx.shared.config
my_cache:set("APPNAME",config.global.gamename)
my_cache:set("APPVERSION",config.global.version)
my_cache:set("MYSQL_CONFIG",cjson.encode(config.mysql))
my_cache:set("REDIS_CONFIG",cjson.encode(config.redis))
my_cache:set("REDIS_CLUSTER_CONFIG",cjson.encode(config.rediscluster))
local ip = config.statusserver.ip
local port = config.statusserver.port
local serverid = config.statusserver.serverid

local function loop()
    --启动消息代理
    print("启动消息代理")
    center.init({ip=ip,port=port, serverid=serverid})
    center.run()
end

ngx.timer.at(1, loop)

