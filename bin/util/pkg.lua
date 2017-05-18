#!/usr/bin/env lua
--- Manage packages for FusionScript
-- @script fusion-pkg
-- @author ChickenNuggers
-- @usage fusion-pkg get ([USER]/[REPO]|git+[https|ssh]://<URL>)
-- or: fusion-pkg upgrade
-- or: fusion-pkg remove [REPO]

local argparse = require("argparse")

local argparser = argparse() {
	name = "fusion-pkg";
	description = "Manage and install packages for FusionScript";
	epilog = "For more info, see https://fusionscript.info";
}

local get = argparser:command "get"
get:argument("repository",
	"GitHub repository or git+:// URL to clone package from")
get:option("-f --from",
	"Website to clone repository (example: https://github.com)",
	"https://github.com/")

local upgrade = argparser:command "upgrade"
upgrade:argument "repository"

local remove = argparser:command "remove"
remove:argument "repository"

local with_dir = "mkdir -p vendor; cd vendor; git clone %s %s --recursive; cd .."
local without_dir = "mkdir -p vendor; cd vendor; git clone %s --recursive; cd .."
local function clone(url, dir)
	if dir then
		os.execute(with_dir:format(url, dir))
	else
		os.execute(without_dir:format(url))
	end
end

local args = argparser:parse()
if args.get then
	local url = args.repository
	if url:match("^git+") then
			clone(url:sub(5))
	elseif url:find("/") then
		if args.from:sub(-1) ~= "/" then
			args.from = args.from .. "/"
		end
		clone(args.from .. url)
	end
elseif args.upgrade then
	if args.repository then
		os.execute(("cd vendor/%s; git pull --recurse-submodules; cd ../..")
			:format(args.repository))
	else
		local lfs = require("lfs")
		lfs.chdir("vendor")
		for dir in lfs.dir(".") do
			if dir:sub(1, 1) ~= "." then
				print("Upgrading " .. dir)
				os.execute(("cd %s; git pull --recurse-submodules; cd ..")
					:format(dir))
			end
		lfs.chdir("..")
		end
	end
elseif args.remove then
	os.execute("rm -rf vendor/" .. args.repository)
end
