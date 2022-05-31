local _M = {}

local rsa = require "rsa"



function _M.rsa_encrypt(plainText,pubKey)
    local encrypted= rsa.encrypt(plainText,pubKey)
    return encrypted
end

function _M.rsa_decrypt(b64cipherText,priKey)
    local data= rsa.decrypt(b64cipherText,priKey)
    return data
end

return _M
