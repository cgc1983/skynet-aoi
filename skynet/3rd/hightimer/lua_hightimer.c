/**********************************************************\
|                                                          |
| xxtea.c                                                  |
|                                                          |
| XXTEA encryption algorithm library for Lua.              |
|                                                          |
| Encryption Algorithm Authors:                            |
|      David J. Wheeler                                    |
|      Roger M. Needham                                    |
|                                                          |
| Code Authors: Chen fei <cf850118@163.com>                |
|               Ma Bingyao <mabingyao@gmail.com>           |
| LastModified: Feb 7, 2016                                |
|                                                          |
\**********************************************************/

#include "lua.h"
#include "lauxlib.h"
#include <sys/time.h>

static int vsec(lua_State *L)
{
    struct timeval t_val;
    gettimeofday(&t_val, NULL);
    lua_pushnumber(L, t_val.tv_sec);
    lua_pushnumber(L, t_val.tv_usec);
    return 2;
}

// static int nsec(lua_State *L)
// {
//     struct timespec t_val;
//     gettimeofday(&t_val, NULL);
//     lua_pushnumber(L, t_val.tv_nsec);
//     return 1;
// }

static const luaL_Reg hightimer[] = {
    {"vsec", vsec},
    {0, 0}
};

LUALIB_API int luaopen_hightimer(lua_State * L) {
#if LUA_VERSION_NUM >= 502 // LUA 5.2 or above
    lua_newtable(L);
    luaL_setfuncs(L, hightimer, 0);
#else
    luaL_register(L, "hightimer", hightimer);
#endif
    return 1;
}
