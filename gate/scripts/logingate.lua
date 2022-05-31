local cjson      = require "cjson"
local cmsgpack   = require "cmsgpack"
local utils      = require "utils"
local crypt = require "crypt"


require "functions"

local server = require "resty.websocket.server"

local wb, err = server:new{
    timeout = 10000,  -- in milliseconds
    max_payload_len = 65535,
}
if not wb then
    ngx.log(ngx.ERR, "failed to new websocket: ", err)
    return ngx.exit(444)
end


local function encode_token(token)
    return string.format("%s@%s:%s",
        ngx.encode_base64(token.user),
        ngx.encode_base64(token.server),
        ngx.encode_base64(token.pass))
end

local function  do_exchange(server,user,password)
    local sock = ngx.socket.tcp()

    local ok, err = sock:connect("127.0.0.1", 8001)
    if not ok then
        return
    end

    ngx.log(ngx.INFO, "tcp ok=", ok, ",err=", err)
    local reader = sock:receiveuntil("\n")
    local data, err, partial = reader()
    ngx.log(ngx.INFO, "receive a data: ", data)
    -- ngx.log(ngx.ERR, "failed to receive a partial: ", partial)
    local challenge = ngx.decode_base64(data)
    ngx.log(ngx.INFO, "receive a challenge: ", challenge)
    local clientkey = crypt.randomkey()
    local s = ngx.encode_base64(crypt.dhexchange(clientkey))
    local bytes, err = sock:send(s.."\n")

    local reader = sock:receiveuntil("\n")
    local secret = crypt.dhsecret(ngx.decode_base64(reader()), clientkey)
    ngx.log(ngx.INFO, "sceret is ", crypt.hexencode(secret))

    local hmac = crypt.hmac64(challenge, secret)
    local s = ngx.encode_base64(hmac)
    local bytes, err = sock:send(s.."\n")


    local token = {
        server = server,
        user = user,
        pass = password,
    }

    local etoken = crypt.desencode(secret, encode_token(token))
    local b = ngx.encode_base64(etoken)
    local bytes, err = sock:send(b.."\n")

    local reader = sock:receiveuntil("\n")
    local result = reader()

    ngx.log(ngx.INFO, "result is ", result)

    local code = tonumber(string.sub(result, 1, 3))
    local subid = ngx.decode_base64(string.sub(result, 5))

    sock:close()
    local handshake = string.format("%s@%s#%s", ngx.encode_base64(token.user), ngx.encode_base64(token.server),ngx.encode_base64(subid))
    local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)
    return code,tonumber(subid),ngx.encode_base64(hmac)
end

local isconn = true
local recv = function()
    while isconn do
        local data, typ, err = wb:recv_frame()
        if not data then
            if not string.find(err, "timeout", 1, true) then
                ngx.log(ngx.ERR, "failed to receive a frame: ", err)
                return ngx.exit(444)
            end
        end

        if typ == "close" then
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
            ngx.log(ngx.INFO, "received a frame of type ", typ, " and payload ", data)
            local msg = cmsgpack.unpack(data)
            if msg.c=="login" and msg.m=="login" then
                ngx.log(ngx.INFO, "received a frame of type msg=",cjson.encode(msg))
                local code,subid,token=do_exchange(msg.data.server,msg.data.user,msg.data.password)
                ngx.log(ngx.INFO, "code=",code,",subid=",subid,",secret=",secret)

                local resp={
                    c="login",
                    m="login",
                    data={
                        server=msg.data.server,
                        user=msg.data.user,
                        subid=subid,
                        token=token,
                    }
                }

                wb:send_binary(cmsgpack.pack(resp))
                wb:send_close()
                isconn=false
            end

        end
    end
end

local co = ngx.thread.spawn(recv)
-- ngx.log(ngx.INFO,"进入等待状态")
ngx.thread.wait(co)
