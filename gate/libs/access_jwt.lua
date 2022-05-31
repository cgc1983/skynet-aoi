local cjson     = require "cjson"
local string    = require "string"
local table_new = require "table.new"
local table     = require "table"
local jwt       = require "resty.jwt"
local redis     = require "redis"
local keysutils = require "keysutils"
local utilsdate = require "utilsdate"
local utils     = require "utils"

require "functions"

local _M={}

function _M.access()
    local arg=ngx.req.get_uri_args()
    local my_cache = ngx.shared.config
    local APPNAME = my_cache:get("APPNAME")
    local APPVERSION = my_cache:get("APPVERSION")
    local secret = APPNAME ..'-'.. APPVERSION
    local jwtval = arg.jwt
    if not jwtval  then
        table.dumpdebug(jwtobj,'jwtobj')
        ngx.say(cjson.encode({errcode=401,errmsg='请求参数错误'}))
        ngx.exit(401)
        return
    end
    local jwtobj = jwt:verify(secret,jwtval)

    if not jwtobj or not jwtobj.payload or  not jwtobj.payload.token or not jwtobj.payload.id then
        ngx.say(cjson.encode({errcode=401,errmsg='参数解析错误'}))
        ngx.exit(401)
        return
    end

    local REDIS_USER_CONFIG = my_cache:get("REDIS_USER_CONFIG")
    REDIS_USER_CONFIG = cjson.decode(REDIS_USER_CONFIG)
    local rediscli = redis:new({host=REDIS_USER_CONFIG.ip, port=REDIS_USER_CONFIG.port})

    if not DEBUG then
        local key = keysutils.get_user_token(jwtobj.payload.id)

        local oldtoken = rediscli:get(key)
        if oldtoken~=jwtobj.payload.token then
            ngx.say(cjson.encode({errcode=400,errmsg='安全检测中...',oldtoken=oldtoken,curtoken=jwtobj.payload.token}))
            ngx.exit(401)
            return
        end
    end

    local args = ngx.req.get_uri_args()
    args.id = jwtobj.payload.id
    ngx.req.set_uri_args(args)
end

return _M
