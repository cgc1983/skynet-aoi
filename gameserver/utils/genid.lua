math.randomseed(os.time())
local hightimer = require("hightimer")
local genid = {}

function genid.gen()
    local a,b = hightimer.nsec()
    return string.format("%d%d",a,b)
end

return genid
