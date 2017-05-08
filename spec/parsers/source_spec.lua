local compiler = require("fusion.core.compilers.source")
local parser = require("fusion.core.parser")

describe("compilers/source", function()
	it("can compile FusionScript code", function()
		compiler.compile(parser:match("print('test');"), function(output)
			assert.same("print(\"test\")", output)
		end)
	end)
	it("can compile FusionScript files", function()
		local input = [[
print("test")
]]
		assert.same(input, compiler.read_file("spec/in/basic.fuse"))
	end)
	it("can load FusionScript files", function()
		local old_print = print
		_G['print'] = function(text)
			assert.same("test", text)
		end
		assert(compiler.load_file("spec/in/basic.fuse"), "unable to load file")()
		_G['print'] = old_print
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
