local parser = require("fusion.core.parsers.source")
local lfs = require("lfs")

describe("parsers/source", function()
	local out_file
	after_each(function()
		if out_file then
			out_file:close()
			out_file = nil
		end
	end)
	for file in lfs.dir("spec/in") do
		if not file:match("^%.") then
			it("can compile file " .. file .. " to Lua source", function()
				local compiled = assert(parser.read_file("spec/in/" .. file))
				out_file = assert(io.open("spec/out/source/" .. file:gsub("fuse",
					"lua")))
				assert.same(out_file:read("*a"), compiled)
			end)
		end
	end
end)
