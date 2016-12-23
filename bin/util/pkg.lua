#!/usr/bin/env lua
--- Manage packages for FusionScript
-- @script fusion-pkg
-- @author ChickenNuggers
-- @usage fusion-pkg get ([USER]/[REPO]|git+[https|ssh]://<URL>)
-- or: fusion-pkg upgrade
-- or: fusion-pkg remove [REPO]

local function clone(url)
	os.execute((
		"mkdir -p vendor; cd vendor; git clone %s --recursive; cd .."):format(
		url))
end

local args = {...}
if args[1] == "get" then
	local url = args[2]
	if url:match("^git+") then
			clone(url:sub(5))
	elseif url:find("/") then
		clone("https://github.com/" .. url)
	end
elseif args[1] == "upgrade" then
	local lfs = require("lfs")
	lfs.chdir("vendor")
	for dir in lfs.dir(".") do
		if dir:sub(1, 1) ~= "." then
			print("Upgrading " .. dir)
			os.execute(("cd %s; git pull --recurse-submodules; cd .."):format(dir))
		end
	end
	lfs.chdir("..")
elseif args[1] == "remove" then
	os.execute("rm -rf vendor/" .. assert(args[2], "Missing repository name"))
elseif not args[1] then
	error("No command given")
else
	error("Unknown option: " .. args[1])
end
