local class = require("fusion.stdlib.class")
local unpack = require("fusion.util").unpack

describe("class", function()
	it("can make a simple class", function()
		local x = class({}, {}, "Test")
		assert.same("Test", tostring(x))
		local instance = x()
		assert.same(x, instance.__class)
		assert.is_nil(instance.__super)
	end)
	it("can use a basic interface", function()
		class({a = 'b'}, {implements = {a = true}}, "Test_Two")
		assert.errors(function()
			class({}, {implements = {a = true}}, "Test_Three")
		end)
	end)
	it("can make a complex class", function()
		local ext = {3, 4}
		local impl = {d = true}
		local args = {'a', 1, false, nil, true}
		local x = class({
			d = 'b',
			__init = function(self)
				assert.is_not.same("function", tostring(self):sub(1, 8))
			end
		}, {extends = ext, implements = impl}, "Class")
		assert.same(tostring(x), "Class")
		local instance = x(unpack(args))
		assert.same(x, instance.__class)
		assert.same(ext, instance.__super)
		assert.same(args, instance.__args)
	end)
end)
