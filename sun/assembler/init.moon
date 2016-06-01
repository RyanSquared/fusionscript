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

function_header = (sink, tree)->
	--[[ documentation for `tree` argument:
	-- `.source` source name (converted using convert_literal_string())
	-- `.line` line defined (0 for file master function)
	-- `.lastline` last line defined (0 for file master function)
	-- `.parameters` list of parameters defined
	-- `.is_vararg` byte saying if is a vararg function
	-- `.maxstacksize` number of registers used
	-- `.instructions` list of instructions to be assembled
	-- `.constants` list of constants to be compiled
	-- `.upvalues` list of upvalues
	-- `.prototypes` list of prototypes
	-- `.debug` {
	--   `.lineinfo` first and last line as two bytes
	--   `.localvars` local variables
	--   `.upvalues` list of upvalues
	-- }
	--]]
