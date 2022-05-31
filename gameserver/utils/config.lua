
local config = {}

local DEFAULT={
    errmsg={
        e50001='系统错误',
        e50002='collection为必传参数',
        e50003='sort参数类型错误, 必须为map',
        e50004='skip参数类型错误, 必须为整数型',
        e50005='limit参数类型错误, 必须为整数型',
        e50006='添加失败',
        e50007='修改失败',
        e50008='doc参数必传',
        e50009='doc类型错误, 必须为map',
        e50010='删除失败',
        e50011='update参数错误, 例:update:{"$set":{"t":"bbb"}}',
        e50012='query参数错误, 必须为map',
        e50013='如果upsert存在则类型必须是布尔值',
        e50014='如果multi存在则类型必须是布尔值',
        e50015='如果justOne存在则类型必须是布尔值',
    },
}

local dbconfig={}
function config.get(...)
    local d = dbconfig
    for _,v in ipairs({...}) do
        local k = v
        d=d[k]
        if not d then
            break
        end
    end
    if d then
        return d
    end

    local d = DEFAULT
    for _,v in ipairs({...}) do
        local k = v
        d=d[k]
        if not d then
            break
        end
    end
    if d then
        return d
    end
    assert(false,'不能走到这里')
end

return config

