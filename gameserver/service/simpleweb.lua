package.path = package.path..";"..PROJ_ROOT.."/utils/?.lua"..";"..PROJ_ROOT.."/handler/?.lua"..";"..PROJ_ROOT.."/gamelogic/?.lua"..";"


local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local datacenter = require "skynet.datacenter"
local cjson = require "cjson"
local mode, protocol = ...
protocol = protocol or "http"

local watchdog = nil
local handlers = {}
if mode == "agent" then

local function response(id, write, ...)
    local ok, err = httpd.write_response(write, ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        skynet.error(string.format("fd----> = %d, %s", id, err))
    end
end

local function split(str, reps)
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function ( w )
        table.insert(resultStrList,w)
    end)
    return resultStrList
end


local SSLCTX_SERVER = nil
local function gen_interface(protocol, fd)
    if protocol == "http" then
        return {
            init = nil,
            close = nil,
            read = sockethelper.readfunc(fd),
            write = sockethelper.writefunc(fd),
        }
    elseif protocol == "https" then
        local tls = require "http.tlshelper"
        if not SSLCTX_SERVER then
            SSLCTX_SERVER = tls.newctx()
            -- gen cert and key
            -- openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -keyout server-key.pem -out server-cert.pem
            local certfile = skynet.getenv("certfile") or "./server-cert.pem"
            local keyfile = skynet.getenv("keyfile") or "./server-key.pem"
            print(certfile, keyfile)
            SSLCTX_SERVER:set_cert(certfile, keyfile)
        end
        local tls_ctx = tls.newtls("server", SSLCTX_SERVER)
        return {
            init = tls.init_responsefunc(fd, tls_ctx),
            close = tls.closefunc(tls_ctx),
            read = tls.readfunc(fd, tls_ctx),
            write = tls.writefunc(fd, tls_ctx),
        }
    else
        error(string.format("Invalid protocol: %s", protocol))
    end
end

skynet.start(function()
    skynet.dispatch("lua", function (_,_,id)
        socket.start(id)
        local interface = gen_interface(protocol, id)
        if interface.init then
            interface.init()
        end

        -- limit request body size to 8192 (you can pass nil to unlimit)
        local code, url, method, header, body = httpd.read_request(interface.read, 8192)
        skynet.error("read_request",code, url,method,body)

        if not watchdog then
            watchdog = datacenter.get('watchdog')
        end

        if code then
            if code ~= 200 then
                response(id, interface.write, code)
            else
                local tmp = {}
                local params = {}
                if header.host then
                    table.insert(tmp, string.format("host: %s", header.host))
                end
                local path, query = urllib.parse(url)
                table.insert(tmp, string.format("path: %s", path))
                if query then
                    local q = urllib.parse_query(query)
                    for k, v in pairs(q) do
                        table.insert(tmp, string.format("query: %s= %s", k,v))
                        params[k]=v
                    end
                end
                table.insert(tmp, "-----header----")
                for k,v in pairs(header) do
                    table.insert(tmp, string.format("%s = %s",k,v))
                end
                table.insert(tmp, "-----body----\n" .. body)
                if body then
                    local q = urllib.parse_query(body)
                    for k, v in pairs(q) do
                        table.insert(tmp, string.format("body: %s= %s", k,v))
                        params[k]=v
                    end
                end
                local path_table = split(path, '/')
                skynet.error('params---->', cjson.encode(params))
                local name = path_table[1]
                local func = path_table[2]
                if not name or not func then
                    response(id, interface.write, code, table.concat(tmp,"\n"))
                else
                    local handlername = string.format("%shandler",name)
                    if not  handlers[handlername] then
                        local ok,handler = pcall(require, handlername)
                        if ok then
                            handlers[handlername] = handler
                        else
                            -- skynet.error("error :",handler)
                            response(id, interface.write, code, table.concat(tmp,"\n"))
                        end
                    end
                    if handlers[handlername] then
                        handler = handlers[handlername]
                        local funcname = string.format("on_%s",func)
                        -- skynet.error("require handler funname ="..tostring(funcname))
                        local ok,resp = pcall(handler[funcname], params)
                        if ok and resp then
                            response(id, interface.write, code, cjson.encode(resp))
                        else
                            response(id, interface.write, code, table.concat(tmp,"\n"))
                        end
                    else
                        -- skynet.error("can not  require handler="..tostring(handlername))
                        response(id, interface.write, code, table.concat(tmp,"\n"))
                    end
                end
            end
        else
            if url == sockethelper.socket_error then
                skynet.error("socket closed")
            else
                skynet.error(url)
            end
        end
        socket.close(id)
        if interface.close then
            interface.close()
        end
    end)
end)

else

skynet.start(function()
	local agent = {}
	local protocol = "http"
	for i= 1, 100 do
		agent[i] = skynet.newservice(SERVICE_NAME, "agent", protocol)
	end
	local balance = 1
	local id = socket.listen("0.0.0.0", 8001)
	-- skynet.error(string.format("Listen web port 8001 protocol:%s", protocol))
	socket.start(id , function(id, addr)
		-- skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
		skynet.send(agent[balance], "lua", id)
		balance = balance + 1
		if balance > #agent then
			balance = 1
		end
	end)
end)

end
