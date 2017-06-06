#!/usr/bin/env lua
--- Print a Lua table containing a FusionScript AST.
-- @script fusion-ast
-- @author ChickenNuggers
-- @usage fusion-ast [FILE]
local argparse = require("argparse")
local parser = require("fusion.core.parser")
local serpent = require("serpent")

local argparser = argparse() {
	name = "fusion-ast";
	description = "Print a Lua table containing FusionScript AST";
	epilog = "For more info, see https://fusionscript.info";
}
argparser:argument("file", "File(s) to parse"):args("+")
local files = argparser:parse().file

local function read_file(file)
	local file_handler = assert(io.open(file))
	local line = file_handler:read()
	if line:sub(1, 2) == "#!" then
		print(serpent.block(parser:match(file_handler:read("*a"))))
	else
		print(serpent.block(parser:match(line .. '\n' ..
			file_handler:read("*a"))))
	end
	file_handler:close()
end

if #files > 1 then
	for file in ipairs(files) do
		print(("--- %s ---"):format(file))
		read_file(file)
	end
else
	read_file(files[1])
end
