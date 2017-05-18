#!/usr/bin/env lua
--- Generate a Lua file from FusionScript code.
-- @script fusionc-source
-- @author ChickenNuggers
-- @usage fusionc-source [OPTIONS] [FILE]
-- fusionc-source [FILE]/[DIRECTORY]
--
--  -p | Write output to stdout
--  -h | Print help information

local argparse = require("argparse")
local compiler = require("fusion.core.compilers.source")
local lfs = require("lfs")

local argparser = argparse() {
	name = "fusionc-source";
	description = "Generate a Lua file from FusionScript code";
	epilog = "Fur more info, see https://fusionscript.info";
}

argparser:argument("file", "Files or directories to compile"):args("+")
argparser:mutex(
	argparser:flag("-p --print", "Print compiled output"),
	argparser:flag("-q --quiet", "Don't print status messages")
)

local function walk(file_func, dir)
	for item in lfs.dir(dir) do
		if item:sub(1, 1) == "." then -- luacheck: ignore 
			-- pass
		elseif lfs.attributes(dir .. "/" .. item, "mode") == "directory" then
			walk(file_func, dir .. "/" .. item)
		else
			pcall(file_func, dir .. "/" .. item)
		end
	end
end

local function process(file, does_output)
	if lfs.attributes(file, "mode") == "directory" then
		return walk(process, file)
	end
	local base = file:match("^(.+)%.fuse$")
	if not base then
		return
	end
	local output = compiler.read_file(file)
	local output_file = io.open(base .. ".lua", "w")
	output_file:write(output .. "\n")
	output_file:close()
	if does_output ~= false then
		print(("Built file %s -> %s"):format(file, base .. ".lua"))
	end
end

local args = argparser:parse()
if args.print then -- two loops are written to run the check only once
	for i, file in ipairs(args.file) do -- luacheck: ignore 213
		io.write(compiler.read_file(file))
	end
else
	for i, file in ipairs(args.file) do -- luacheck: ignore 213
		process(file, not args.quiet)
	end
end
