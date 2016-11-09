#!/usr/bin/env lua
local lexer = require("fusion.core.lexer")
local pretty = require("pl.pretty")


local args = {...}
if #args > 1 then
	for file in ipairs(args) do
		print(("--- %s ---"):format(file))
		local file_handler = assert(io.open(file))
		pretty.dump(lexer:match(file_handler:read("*a")))
		file_handler:close()
	end
else
	local file_handler = assert(io.open(args[1]))
	pretty.dump(lexer:match(file_handler:read("*a")))
	file_handler:close()
end
