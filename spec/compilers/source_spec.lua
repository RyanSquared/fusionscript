local compiler = require("fusion.core.compilers.source")
local parser = require("fusion.core.parser")
local lfs = require("lfs")

describe("compilers/source", function()
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
				local compiled = assert(compiler.read_file("spec/in/" .. file))
				out_file = assert(io.open("spec/out/source/" .. file:gsub("fuse",
					"lua")))
				assert.same(out_file:read("*a"), compiled)
			end)
		end
	end
	it("can compile FusionScript code", function()
		compiler.compile(parser:match("print('test');"), function(output)
			assert.same("print(\"test\")", output)
		end)
	end)
	it("can error out with bad AST", function()
		assert.errors(function()
			local c = compiler:new()
			c:transform('errors') -- gives type error
		end)
		assert.errors(function()
			local c = compiler:new()
			c:transform({'errors'}) -- gives error about being bad node
		end)
	end)
	it("can load FusionScript files", function()
		local old_print = print
		_G['print'] = function(text)
			assert.same("test", text)
		end
		assert(compiler.load_file("spec/in/basic.fuse"), "unable to load file")()
		_G['print'] = old_print
	end)
	it("can inject FusionScript extensions to the global environment", function()
		-- empty test just to run without errors
		compiler.inject_extensions()
	end)
	it("can load a searcher into the module loading system", function()
		assert.same(true, compiler.inject_loader())
		local len = #(package.loaders or package.searchers) -- luacheck: ignore 143
		assert.same(compiler.search_for, (package.loaders or package.searchers)[len]) -- luacheck: ignore 143
		assert.same(false, compiler.inject_loader()) -- false if already run
	end)
	it("can load FusionScript modules", function()
		assert.same(0xDEADBEEF, require("spec.misc"))
		assert.errors(function()require(os.tmpname())end)
	end)
end)
