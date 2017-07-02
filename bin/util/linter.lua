#!/usr/bin/env lua
--- Check a FusionScript file for syntax and logical errors
-- @script fusion-lint
-- @usage fusion-lint [-h] [FILE]
local argparse = require("argparse")
local parser = require("fusion.core.parser")
local unpack = require("fusion.util").unpack
local lfs = require("lfs")

local argparser = argparse() {
	name = "fusion-lint";
	description = "Check a FusionScript file for syntax and logical errors";
	epilog = "For more info, see https://fusionscript.info";
}
argparser:argument("file", "File(s) to lint"):args("*")
argparser:flag("-i", "Read from input")
argparser:option("--filename", "Filename to use when printing errors")
argparser:option("--compiler",
	"Compiler to use for checking compile-time errors", "source")
local options = argparser:parse()
local files = options.file

local function lint_file(file_name, file)
	local messages = {}
	local is_parsed, result = pcall(parser.match, parser, file:read("*a"),
		file_name)
	if not is_parsed then
		local message = result.msg[2]
		local pos = result.pos
		messages[#messages + 1] =
			("%s:%d:%d: (E001) %s"):format(file_name, pos.y, pos.x, message)
	else -- luacheck: ignore 542
		-- ::TODO:: do the actual linting here
	end
	return messages
end

local function get_files(path, file_list)
	-- recursively add all files found in a path to `file_list`
	local file_type = assert(lfs.attributes(path, "mode"))
	if file_type == "directory" then
		for item in lfs.dir(path) do
			if item:sub(1, 1) ~= "." then
				get_files(path .. "/" .. item, file_list)
			end
		end
	elseif file_type == "file" then
		table.insert(file_list, {path, assert(io.open(path))})
	else
		error(("incorrect filetype for %s: %s (not file/directory)"):format(
			path, file_type))
	end
	return file_list
end

if options.i then
	for _, line in ipairs(lint_file(options.filename or "stdin", io.stdin)) do
		print(line)
	end
else
	local to_process = {}
	for _, path in ipairs(files) do
		for _, file in pairs(get_files(path, {})) do
			table.insert(to_process, file)
		end
	end
	for _, file in ipairs(to_process) do
		for _, line in ipairs(lint_file(unpack(file))) do
			print(line)
		end
	end
end
