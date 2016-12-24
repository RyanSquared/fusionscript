#!/usr/bin/env lua
--- Generate a Lua file from FusionScript code.
-- @script fusionc-source
-- @author ChickenNuggers
-- @usage fusionc-source [OPTIONS] [FILE]
-- fusionc-source [FILE]/[DIRECTORY]
--
--  -p | Write output to stdout
--  -h | Print help information

local parser = require("fusion.core.parsers.source")
local lfs = require("lfs")

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

local function process(file, does_output)
	if lfs.attributes(file, "mode") == "directory" then
		return walk(process, file)
	end
	local base = file:match("^(.+)%.fuse$")
	local output = parser.read_file(file)
	local output_file = io.open(base .. ".lua", "w")
	output_file:write(output .. "\n")
	output_file:close()
	if does_output ~= false then
		print(("Built file %s -> %s"):format(file, base .. ".lua"))
	end
end

local args = {...}
local arg_index = 1
while arg_index <= #args do
	local _arg = args[arg_index]
	if _arg == "-p" then
		arg_index = arg_index + 1
		for i=arg_index, #args do
			io.write(parser.read_file(args[i]))
		end
		break
	elseif _arg == "--help" or _arg == "-h" then
		local program = arg[0]:match(".+/(.-)$") or arg[0]
		local usage = {
			("Usage: %s [OPTIONS] [FILE]"):format(program);
			("   or: %s [FILE/DIRECTORY]"):format(program);
			("");
			("\t-p | Write output to stdout");
			("\t-h | Print help information")
		}
		print(table.concat(usage, "\n"))
		break
	else
		process(_arg)
		arg_index = arg_index + 1
	end
end
