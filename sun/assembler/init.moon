-- vim:set noet sts=0 sw=3 ts=3:

util = require "sun.assembler.util"

header = (sink)->
	resume = (sink, value)-> coroutine.resume sink, type(value) == "string" or string.byte(value)
	-- first bytes of header
	resume sink, "\27Lua"
	resume sink, 0x53
	resume sink, util.grab_luac_data!
	-- size checks
	sizes = util.check_sizes!
	resume sink, sizes.int
	resume sink, sizes.size_t
	resume sink, sizes.Instruction
	resume sink, sizes.lua_Integer
	resume sink, sizes.lua_Number
	-- LUAC_INT and LUAC_NUM
	resume sink, util.check_luac_int!
	resume sink, util.check_luac_num!
