describe("table", function()
	local table = require("fusion.stdlib.table")
	it("can copy tables", function()
		local t0 = {"a", "b", "c", "d", "e"}
		local t1 = table.copy(t0)
		assert.same(t0, t1)
		assert.is_not.same(tostring(t0), tostring(t1))
	end)
	it("can create a table from an iterator", function()
		local t0 = {"a", "b", "c"}
		assert.same(t0, table.from_generator(pairs(t0)))
	end)
	it("can replace values in a table from a new table", function()
		local t0 = {a = "b"}
		local t1 = {a = "c"}
		assert.same(t1, table.join(t0, t1))
		assert.same(t0, table.join(t1, t0))
	end)
	it("can return a table after sorting", function()
		local t0 = {}
		assert.same(t0, table.sort(t0))
	end)
	it("can grab a slice of a table", function()
		local base = {'a', 'b', 'c', 'd', 'e'}
		local first = {'a', 'b', 'c'}
		local last = {'c', 'd', 'e'}
		assert.same(base, table.from_generator(table.slice(base)))
		assert.same(first, table.from_generator(table.slice(base, 1, 3)))
		assert.same(last, table.from_generator(table.slice(base, 3)))
	end)
end)
