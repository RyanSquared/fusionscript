#!/usr/bin/env lua
--- Run FusionScript code with the Lua VM.
-- @script fusion-source
-- @author ChickenNuggers
-- @usage fusion-source [OPTIONS] [FILE]
-- fusion-source [FILE]
--
--   --metadata <package> | Print metadata for package
--   -m <package>         | Run <package>.main module
--   -h                   | Print help information

local argparse = require("argparse")
local compiler = require("fusion.core.compilers.source")
compiler.inject_loader()
compiler.inject_extensions()

local argparser = argparse() {
	name = "fusion-source";
	description = "Run FusionScript code with the Lua VM";
	epilog = "For more info, see https://fusionscript.info";
}

argparser:mutex(
	argparser:flag("--metadata", "Print metadata information for a package"),
	argparser:flag("--package", "Run <package>.main module")
)

argparser:argument("file", "File to run")

local args = argparser:parse()

_G.compiler = compiler

if args.metadata then
	local ok, module = pcall(require, args.file .. ".metadata")
	if not ok then
		error("Could not find module metadata for package: " .. args.file ..
			"\n" .. module)
	else
		local function check(name)
			assert(module[name], "Missing field: " .. name)
		end
		local opts = {"version", "description", "author", "copyright",
			"license"}
		for _, name in ipairs(opts) do
			check(name)
		end
		for _, name in ipairs(opts) do
			local value = module[name]
			local _type = type(value)
			if _type == "string" then
				print(("['%s'] = %q"):format(name, value))
			else
				print(("['%s'] = %s"):format(name, tostring(value)))
			end
		end
	end
elseif args.package then
	local module = args.file
	require(module .. ".main")
else
	local file = assert(args.file:match("^.+%.fuse"),
		("Incorrect filetype: %s"):format(args.file))
		compiler.do_file(file)
end
