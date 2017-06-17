#!/usr/bin/env lua
--- Check a FusionScript file for syntax and logical errors
-- @script fusion-lint
-- @usage fusion-lint [-h] [FILE]
local argparse = require("argparse")
local parser = require("fusion.core.parser")
local unpack = require("fusion.util").unpack

local argparser = argparse() {
	name = "fusion-lint";
	description = "Check a FusionScript file for syntax and logical errors";
	epilog = "For more info, see https://fusionscript.info";
}
argparser:argument("file", "File(s) to lint"):args("*")
argparser:flag("-i", "Read from input")
argparser:option("--filename", "Filename to use when printing errors")
local options = argparser:parse()
local files = options.files

local function lint_file(file_name, file)
	local messages = {}
	local is_linted, result = pcall(parser.match, nil, file:read("*a"))
	if not is_linted then
		local message = result.msg[2]
		local pos = result.pos
		messages[#messages + 1] =
			("%s:%d:%d: (E001) %s"):format(file_name, pos.y, pos.x, message)
	else -- luacheck: ignore
		-- pass
	end
	return messages
end

if options.i then
	for _, line in ipairs(lint_file(options.filename or "stdin", io.stdin)) do
		print(line)
	end
else
	for index, file in ipairs(files) do
		files[index] = {file, assert(io.open(file))} -- TODO: support for dirs
	end

	for _, file in ipairs(files) do
		for _, line in ipairs(lint_file(unpack(file))) do
			print(line)
		end
	end
end
