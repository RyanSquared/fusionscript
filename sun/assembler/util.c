// vim:set noet sts=0 sw=2 ts=2:
#include <stdio.h>
#include <unistd.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "lua/src/lundump.h"

#define SUN_VERSION "0.1.0"
#define SUN_COPYRIGHT "Copyright (c) 2016 Ryan"

#define sun_set_size(L, string, item) \
	lua_pushstring(L, string);\
	lua_pushinteger(L, sizeof(item));\
	lua_settable(L, -3);

int sun_check_sizes(lua_State *L) {
	lua_newtable(L);
	sun_set_size(L, "int", int);
	sun_set_size(L, "size_t", size_t);
	sun_set_size(L, "Instruction", Instruction);
	sun_set_size(L, "lua_Integer", lua_Integer);
	sun_set_size(L, "lua_Number", lua_Number);
	return 1;
}

int sun_grab_luac_data(lua_State *L) {
	lua_pushliteral(L, LUAC_DATA);
	return 1;
}

int sun_check_luac_num(lua_State *L) {
	union LuaNumberToChar {
		char c[sizeof(lua_Number)];
		lua_Number n;
	} conv;
	conv.n = LUAC_NUM;
	lua_pushlstring(L, conv.c, sizeof(lua_Number));
	return 1;
}

int sun_check_luac_int(lua_State *L) {
	union LuaIntegerToChar {
		char c[sizeof(lua_Integer)];
		lua_Integer n;
	} conv;
	conv.n = LUAC_INT;
	lua_pushlstring(L, conv.c, sizeof(lua_Integer));
	return 1;
}

static const struct luaL_Reg sun_assembler_util_lib[] = {
	{"check_sizes", sun_check_sizes},
	{"grab_luac_data", sun_grab_luac_data}
	{"check_luac_num", sun_check_luac_num},
	{"check_luac_int", sun_check_luac_int},
	{NULL, NULL}
};

int luaopen_sun_assembler_util(lua_State *L) {
	luaL_newlib(L, sun_assembler_util_lib);
	lua_pushliteral(L, SUN_VERSION);
	lua_setfield(L, -2, "_VERSION");
	lua_pushliteral(L, SUN_COPYRIGHT);
	lua_setfield(L, -2, "_COPYRIGHT");
	return 1;
}
