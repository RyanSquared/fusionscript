#!/usr/bin/env lua
--- Generate a Lua file from FusionScript code.
-- @script fusionc-source
-- @author ChickenNuggers
-- @usage fusionc-source [FILE]/[DIRECTORY]

local parser = require("fusion.core.parsers.source")
local lfs = require("lfs")

local function process(file, does_output)
	assert(file:match("%.fuse$"), ("Incorrect filetype: %s"):format(file))
	local base = file:match("^(.+)%.fuse$")
	local output = parser.read_file(file)
	local output_file = io.open(base .. ".lua", "w")
	output_file:write(output .. "\n")
	output_file:close()
	if does_output ~= false then
		print(("Built file %s -> %s"):format(file, base .. ".lua"))
	end
end

local function walk(file_func, dir)
	for item in lfs.dir(dir) do
		if item:sub(1, 1) == "." then -- luacheck: ignore 
			-- pass
		elseif lfs.attributes(dir .. "/" .. item, "mode") == "directory" then
			walk(file_func, dir .. "/" .. item)
		else
			print(pcall(file_func, dir .. "/" .. item))
		end
	end
end

local args = {...}
if #args > 1 then
	for file in ipairs(args) do
		process(file)
	end
elseif lfs.attributes(args[1], "mode") == "directory" then
	walk(process, args[1])
else
	process(args[1])
end
