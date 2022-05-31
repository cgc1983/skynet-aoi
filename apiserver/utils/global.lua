local cjson = require "cjson"
local _M={}

local conf=nil

function _M.set_config(config)
    conf=config

    local mysql_cnf = {
        ip = config.mysql.host,
        port = config.mysql.port,
        db = config.mysql.database,
        user=config.mysql.user,
        password=config.mysql.password,
        max_packet_size = 1024 * 1024,
    }
    conf.mysql=mysql_cnf

    assert(#conf.redis_cluster.hosts==#conf.redis_cluster.ports,"redis cluster的节点个数和端口必须一样")

    local serv_list={}
    for i=1,#conf.redis_cluster.ports do
        table.insert(serv_list,{ip=conf.redis_cluster.hosts[i],port=conf.redis_cluster.ports[i]})
    end

    local redis_cluster_cnf= {
        name = conf.name,                   --rediscluster name
        serv_list = serv_list,
        keepalive_timeout = 60000,              --redis connection pool idle timeout
        keepalive_cons = 64,                    --redis connection pool size
        connect_timeout = 1000,                 --timeout while connecting
        read_timeout = 1000,                    --timeout while reading
        send_timeout = 1000,                    --timeout while sending
        max_redirection = 5,                    --maximum retry attempts for redirection
        auth = conf.redis_cluster.auth
    }

    conf.redis_cluster=redis_cluster_cnf
    -- conf.redis.timeout=10*1000
end

function _M.get_mysql_conf()
    return conf.mysql
end

function _M.get_redis_config()
    return conf.redis
end


function _M.get_redis_cluster_config()
    return conf.redis_cluster
end

function _M.get_ip()
    if not ip then
        local IP = my_cache:get("IP")
        ip = IP
    end
    return ip or "192.168.3.235"
end


function _M.get_port()
    if not port then
        local PORT = my_cache:get("PORT")
        port = PORT
    end
    return port or 9080
end


function _M.get_socket_ip()
    if socket_ip then
        local SOCKET_IP = my_cache:get("SOCKET_IP")
        socket_ip = SOCKET_IP
    end
    return socket_ip or "192.168.3.15"
end


function _M.get_socket_port()
    if socket_port then
        local SOCKET_PORT = my_cache:get("SOCKET_PORT")
        socket_port = SOCKET_PORT
    end
    return socket_port or 8083
end

return _M
