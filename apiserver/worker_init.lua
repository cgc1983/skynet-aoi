local cjson  = require "cjson"
local redis  = require "redis"
local global = require "global"
local utils  = require "utils"
local toml   = require "toml"

ngx.log(ngx.INFO,"worker init")
local workerId = ngx.worker.id()

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

if file_exists("../conf/dev.toml") then
    DEBUG = true
    local content = read_file("../conf/dev.toml")
    config=toml.parse(content)
else
    local content = read_file("../conf/prod.toml")
    config=toml.parse(content)
end

ngx.log(ngx.DEBUG,cjson.encode(config))
global.set_config(config)

