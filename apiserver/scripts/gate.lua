local template = require "template"
local global   = require "global"
local mysql    = require "mysql"
local cjson    = require "cjson"
local errorx   = require "errorx"

ngx.header['Content-Type'] = 'application/json; charset=utf-8'

errorx.say_success({
    tcp={
        login={
            ip="127.0.0.1",
            port=8001,
        },
        game={
            ip="127.0.0.1",
            port=8888,
        }
    },
    ws={
        login="ws://127.0.0.1:8866/login",
        game="ws://127.0.0.1:8866/game",
    },
    status=0,
})