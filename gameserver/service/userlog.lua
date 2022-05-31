local skynet = require "skynet"
require "skynet.manager"
local fd=nil
local fname=nil
local logfolder =nil

skynet.register_protocol {
    name = "text",
    id = skynet.PTYPE_TEXT,
    unpack = skynet.tostring,
    dispatch = function(_, address, msg)
        if not logfolder then
            return
        end
        local now=os.date("*t",os.time())
        local s=""..now.year..now.month..now.day
        local foldername = string.format("%d_%02d_%02d.log",now.year,now.month,now.day)

        local logpath=logfolder..foldername
        if (not fname) or logpath~=fname then
            if fd then
                fd:close()
                fd=nil
            end
            fname = logpath
        end

        if not fd then
            fd=io.open(logpath,"a+")
        end

        if fd then
            local content = string.format("%s:%08x(%.2f): %s",os.date("%y/%m/%d %H:%M:%S"), address, skynet.time(), msg..'\r\n')
            print(content)
            fd:write(content)
            fd:flush()
        else
            --print(fname)
        end
    end

}

skynet.register_protocol {
    name = "SYSTEM",
    id = skynet.PTYPE_SYSTEM,
    unpack = function(...) return ... end,
    dispatch = function()
        if not fd then
            fd:close()
            fname=nil
        end
    end

}

skynet.start(function()
    logfolder =PROJ_ROOT.."/log/"
    local err=os.execute("mkdir "..logfolder)
    skynet.register ".logger"
end)
