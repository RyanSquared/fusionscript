#!/usr/bin/env lua
--- Print a Lua table containing a FusionScript AST.
-- @script fusion-ast
-- @author ChickenNuggers
-- @usage fusion-ast [FILE]
local parser = require("fusion.core.parser")
local pretty = require("pl.pretty")

local function read_file(file)
	local file_handler = assert(io.open(file))
	local line = file_handler:read()
	if line:sub(1, 2) == "#!" then
		pretty.dump(parser:match(file_handler:read("*a")))
	else
		pretty.dump(parser:match(line .. '\n' .. file_handler:read("*a")))
	end
	file_handler:close()
end

local args = {...}
if #args > 1 then
	for file in ipairs(args) do
		print(("--- %s ---"):format(file))
		read_file(file)
	end
else
	read_file(args[1])
end
