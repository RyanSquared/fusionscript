#!/usr/bin/env lua
local parser = require("fusion.core.parsers.source")
local lfs = require("lfs")

function process(file, does_output)
	assert(file:match("%.fuse$"), ("Incorrect filetype: %s"):format(file))
	parser.do_file(file)
end

local args = {...}
process(args[1])
