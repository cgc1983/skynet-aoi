local cjson      = require "cjson"
local cmsgpack   = require "cmsgpack"
local utils      = require "utils"
local crypt = require "crypt"


require "functions"

local server = require "resty.websocket.server"

local wb, err = server:new{
    timeout = 15000,  -- in milliseconds
    max_payload_len = 65535,
}
if not wb then
    ngx.log(ngx.ERR, "failed to new websocket: ", err)
    return ngx.exit(444)
end

local isconn = true


local sock = ngx.socket.tcp()
local ok, err = sock:connect("127.0.0.1", 8888)
if err or not ok  then
    isconn=false
    ngx.log(ngx.ERR, "connect skynet gameserver error:", err)
    return ngx.exit(444)
end

sock:settimeout(1000)

local recv1=function()
    while isconn do
        --按照skynet的协议格式解析数据
        local head, err, partial = sock:receive(2)

        if err and not string.find(err, "timeout", 1, true) then
            ngx.log(ngx.ERR,"skynet socket close,err=",err)
            isconn=false
            wb:send_close()
            sock:close()
            break
        end

        if head then
            local datalen = string.sub(head,1,2)
            local len = utils.bytes_to_int(datalen,'big')
            local data, err  = sock:receive(len)  -- read a line from downstream

            if err then
                ngx.log(ngx.ERR,"skynet socket close")
                isconn=false
                wb:send_close()
                sock:close()
                break
            end

            wb:send_binary(data)
        end
    end

    ngx.log(ngx.DEBUG,"skynet socket quit")
end

local co1 = ngx.thread.spawn(recv1)

local recv2 = function()
    while isconn do
        local data, typ, err = wb:recv_frame()
        if not data then
            if not string.find(err, "timeout", 1, true) then
                ngx.log(ngx.ERR, "failed to receive a frame: ", err)
                return ngx.exit(444)
            end
        end

        if typ == "close" then
            isconn=false
            sock:close()
            local code = err
            local bytes, err = wb:send_close(1000, "enough, enough!")
            if not bytes then
                ngx.log(ngx.ERR, "failed to send the close frame: ", err)
                break
            end
            ngx.log(ngx.INFO, "closing with status code ", code, " and message ", data)
            break
        end

        if typ == "ping" then
            -- send a pong frame back:
            local bytes, err = wb:send_pong(data)
            if not bytes then
                ngx.log(ngx.ERR, "failed to send frame: ", err)
                return
            end
        elseif typ == "pong" then
            -- just discard the incoming pong frame
        else
            -- handle data
            ngx.log(ngx.DEBUG, "game gate received a frame of type ", typ, " and payload ", data)
            sock:send(utils.pack(data))
        end
    end
end

local co2 = ngx.thread.spawn(recv2)
ngx.thread.wait(co1,co2)
ngx.log(ngx.DEBUG," client logout ")

