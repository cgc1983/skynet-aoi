local keysutils={}

function keysutils.get_lastmsgid_key(uid)
    local key = string.format("%s:user:lastmsgid:%s", APPNAME, tostring(uid))
    return key
end

function keysutils.get_lastunreadmsgid_key(group_id, uid)
    local key = string.format("%s:lastmsgid:%s:%s", APPNAME, tostring(group_id), tostring(uid))
    return key
end

function keysutils.buynumkeyname(id, level)
    return string.format("%s:buynum:%s:%s", APPNAME, tostring(id), tostring(level))
end

function keysutils.user_group_speak(group_id, userid)
    return string.format("%s:group:speak:%s:%s", APPNAME, tostring(group_id), tostring(userid))
end


function keysutils.pig_rare_attr_key(userid, mark)
    return string.format("%s:rareattr:%s:%s", APPNAME, tostring(userid), tostring(mark))
end



return keysutils






















