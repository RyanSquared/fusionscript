// vim:set noet sts=0 sw=2 ts=2:
#include <stdio.h>
#include <stdlib.h>
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
	union lua_number_to_char {
		char c[sizeof(lua_Number)];
		lua_Number n;
	} conv;
	conv.n = LUAC_NUM;
	lua_pushlstring(L, conv.c, sizeof(lua_Number));
	return 1;
}

int sun_check_luac_int(lua_State *L) {
	union lua_integer_to_char {
		char c[sizeof(lua_Integer)];
		lua_Integer n;
	} conv;
	conv.n = LUAC_INT;
	lua_pushlstring(L, conv.c, sizeof(lua_Integer));
	return 1;
}

int sun_convert_literal_string(lua_State *L) {
	luaL_checkstring(L, 1);
	int length = luaL_len(L, 1);
	const char* input = luaL_checkstring(L, 1);
	char* output = malloc(sizeof(size_t) + length + 1);
	union size_t_to_char { // ^ Lua doesn't include embedded '\0'
		char c[sizeof(size_t)];
		size_t s;
	} conv;
	conv.s = length + 1;
	for (int i=0; i < sizeof(size_t); i++) {
		output[i] = conv.c[i]; // manually copy to avoid '\0' errors
	}
	for (int i=0; i < length; i++) {
		output[sizeof(size_t) + i] = input[i];
	}
	output[sizeof(size_t) + length] = '\0';
	lua_pushlstring(L, output, sizeof(size_t) + length + 1);
	return 1;
}

static const struct luaL_Reg sun_assembler_util_lib[] = {
	{"check_sizes", sun_check_sizes},
	{"grab_luac_data", sun_grab_luac_data},
	{"check_luac_num", sun_check_luac_num},
	{"check_luac_int", sun_check_luac_int},
	{"convert_literal_string", sun_convert_literal_string},
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
