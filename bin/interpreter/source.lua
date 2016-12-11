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
local parser = require("fusion.core.parsers.source")
parser.inject_loader()

local arg_index = 1
while arg_index <= #arg do
	if arg[arg_index] == "--metadata" then -- return metadata from module
		assert(arg[arg_index + 1], "missing argument to --metadata: module")
		local ok, module = pcall(require, arg[arg_index + 1] ..
			".metadata")
		if not ok then
			error("Could not find module metadata for package: " ..
				arg[arg_index + 1])
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
			break
		end
	elseif arg[arg_index] == "-m" then -- load <module>.main and exit
		local module = arg[arg_index + 1]
		assert(module, "missing argument to -m: module")
		require(module .. ".main")
		break
	elseif arg[arg_index] == "-h" or arg[arg_index] == "--help" then -- print help
		local program = arg[0]:match(".+/(.-)$") or arg[0]
		local usage = {
			("Usage: %s [OPTIONS] [PACKAGE]"):format(program);
			("   or: %s [FILE]"):format(program);
			("");
			("\t--metadata <package> | Print metadata for package");
			("\t-m <package>         | Run <package>.main module");
			("\t-h                   | Print help information")
		}
		print(table.concat(usage, "\n"))
		break
	else -- run a file
		local file = assert(arg[arg_index]:match("^.+%.fuse"),
			("Incorrect filetype: %s"):format(arg[arg_index]))
		parser.do_file(file)
		break
	end
	arg_index = arg_index + 1
end
