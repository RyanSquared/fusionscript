#!/usr/bin/env lua
local parser = require("fusion.core.parsers.source")
local lfs = require("lfs")

local stp = require("StackTracePlus")

function process(file, does_output)
	assert(file:match("%.fuse$"), ("Incorrect filetype: %s"):format(file))
	xpcall(parser.do_file, function()print(stp.stacktrace())end, file)
end

local args = {...}
process(args[1])
