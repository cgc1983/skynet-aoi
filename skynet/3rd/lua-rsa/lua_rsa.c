/*******************************************************************************************
 *
 *  Copyright (C) Ravishanker Kusuma / ecofast.  All Rights Reserved.
 *
 *  File: rsautils.c 
 *  Date: 2017/12/01
 *  Desc: RSA Encryption & Decryption utils with OpenSSL in C
 *
 *  Thks: http://hayageek.com/rsa-encryption-decryption-openssl-c/
 *
 *  Compilation Command: gcc rsautils.c -fPIC -shared -lssl -lcrypto -o librsa.so
 *******************************************************************************************/
#include "lua.h"
#include "lauxlib.h"

#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/rsa.h>
#include <openssl/evp.h>
#include <openssl/bio.h>

const int padding = RSA_PKCS1_PADDING;

int public_encrypt(unsigned char* data, int data_len, unsigned char* key, unsigned char* encrypted)
{
	int ret = -1;
	BIO* keybio = BIO_new_mem_buf(key, -1);
	if (keybio != NULL)
	{
		RSA* rsa = NULL;
		rsa = PEM_read_bio_RSA_PUBKEY(keybio, &rsa, NULL, NULL);
		if (rsa != NULL)
		{
			ret = RSA_public_encrypt(data_len, data, encrypted, rsa, padding);
			RSA_free(rsa);
		}
		BIO_free_all(keybio);
	}
    return ret;
}

int private_decrypt(unsigned char* enc_data, int data_len, unsigned char* key, unsigned char* decrypted)
{
	int ret = -1;
	BIO* keybio = BIO_new_mem_buf(key, -1);
	if (keybio != NULL)
	{
		RSA* rsa = NULL;
		rsa = PEM_read_bio_RSAPrivateKey(keybio, &rsa, NULL, NULL);
		if (rsa != NULL)
		{
			ret = RSA_private_decrypt(data_len, enc_data, decrypted, rsa, padding);
			RSA_free(rsa);
		}
		BIO_free_all(keybio);
	}
    return ret;
}


static int lencrypt (lua_State *L) {
	luaL_argcheck(L, lua_gettop(L) == 2, 2, "expected 2 argument");

	size_t data_len;
	size_t key_len;

	const char* data;
	const char* key;
	data = luaL_checklstring(L, 1, &data_len);
	key = luaL_checklstring(L, 2, &key_len);

	unsigned char buf[2048];
	memset(buf,0,sizeof(buf));

	size_t len = public_encrypt(data,data_len,key,buf);
	lua_pushlstring(L,buf,len);
  	return 1;
}

static int ldecrypt (lua_State *L) {
	luaL_argcheck(L, lua_gettop(L) == 2, 2, "expected 2 argument");

	size_t data_len;
	size_t key_len;

	const char* data;
	const char* key;
	data = luaL_checklstring(L, 1, &data_len);
	key = luaL_checklstring(L, 2, &key_len);

	unsigned char buf[2048];
	memset(buf,0,sizeof(buf));

	size_t len = private_decrypt(data,data_len,key,buf);
	lua_pushlstring(L,buf,len);
  	return 1;
}

static const luaL_Reg rsa[] = {
    {"encrypt", lencrypt},
    {"decrypt", ldecrypt},
    {0, 0}
};

LUALIB_API int luaopen_rsa(lua_State * L) {
#if LUA_VERSION_NUM >= 502 // LUA 5.2 or above
    lua_newtable(L);
    luaL_setfuncs(L, rsa, 0);
#else
    luaL_register(L, "rsa", rsa);
#endif
    return 1;
}
