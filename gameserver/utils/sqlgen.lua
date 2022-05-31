--sql 语句辅助生成工具
local _M={}

function _M.update(tablename,row,conds)
    local vals = {}
    for k,v in pairs(row) do
        if type(v) =='string' then
            table.insert(vals,string.format("%s='%s'",k,v))
        elseif type(v) =='number' then
            table.insert(vals,string.format("%s=%s",k,tostring(v)))
        else
            local s = string.format("not support %s %s",k,tostring(v))
            assert(false, s)
        end
    end

    local strvals = table.concat(vals,",")
    local fmt = "update `%s` set %s where %s"
    local sql = string.format(fmt,tablename,strvals,conds)
    return sql
end

function _M.insert(tablename,row)

    local cols = {}
    local vals = {}
    for k,v in pairs(row) do
        table.insert(cols,k)

        if type(v) =='string' then
            table.insert(vals,string.format("'%s'",v))
        elseif type(v) =='number' then
            table.insert(vals,string.format("%s",tostring(v)))
        else
            assert(false,'not support')
        end
    end

    local strcols = table.concat(cols,",")
    local strvals = table.concat(vals,",")
    local fmt = "insert into `%s` (%s) values(%s)"
    local sql = string.format(fmt,tablename,strcols,strvals)
    return sql
end



return _M
