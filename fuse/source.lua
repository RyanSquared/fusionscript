#!/usr/bin/env lua
local parser = require("fusion.core.parsers.source")

function process(file)
	assert(file:match("%.fuse$"), ("Incorrect filetype: %s"):format(file))
	local base = file:match("^(.+)%.fuse$")
	local output = parser.read_file(file)
	local output_file = io.open(base .. ".lua", "w")
	output_file:write(output .. "\n")
	output_file:close()
	print(("Built file %s -> %s"):format(file, base .. ".lua"))
end

local args = {...}
if #args > 1 then
	for file in ipairs(args) do
		print(("--- %s ---"):format(file))
		process(file)
	end
else
	process(args[1])
end
