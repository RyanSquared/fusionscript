#!/usr/bin/env lua
local parser = require("fusion.core.parsers.source")

function process(file)
	print(parser.read_file(file))
end

-- ::TODO:: output to respective .lua files

local args = {...}
if #args > 1 then
	for file in ipairs(args) do
		print(("--- %s ---"):format(file))
		process(file)
	end
else
	process(args[1])
end
