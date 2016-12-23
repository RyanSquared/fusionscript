local parser = require("fusion.core.parsers.source")
local lexer = require("fusion.core.lexer")

describe("parsers/source", function()
	it("can compile FusionScript code", function()
		local input_stream = coroutine.wrap(function()
			coroutine.yield(lexer:match("print('test');")[1])
		end)
		parser.compile(input_stream, function(output)
			assert.same("print(\"test\")", output)
		end)
	end)
	it("can compile FusionScript files", function()
		local input = [[
print("test")
]]
		assert.same(input, parser.read_file("spec/in/basic.fuse"))
	end)
	it("can load FusionScript files", function()
		local old_print = print
		_G['print'] = function(text)
			assert.same("test", text)
		end
		assert(parser.load_file("spec/in/basic.fuse"), "unable to load file")()
		_G['print'] = old_print
	end)
	it("can load a searcher into the module loading system", function()
		assert.same(true, parser.inject_loader())
		assert.same(false, parser.inject_loader()) -- false if already run
	end)
	it("can run FusionScript files", function()
		assert.same(0xDEADBEEF, require("spec.misc"))
	end)
end)
