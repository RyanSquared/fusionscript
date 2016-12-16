describe("functional", function()
	local fnl = require("fusion.stdlib.functional")
	local itr = require("fusion.stdlib.iterable")
	local table = require("fusion.stdlib.table")
	it("can iterate correctly (_iter())", function()
		local base_table = {
			a = "hello";
			b = "world";
		}
		for k, v in fnl._iter(base_table) do
			assert.same(base_table[k], v)
		end
	end)
	it("can iterate using another iterator", function()
		local base_table = {
			a = "hello";
			b = "world";
		}
		for k, v in fnl._iter(pairs(base_table)) do
			assert.same(base_table[k], v)
		end
	end)
	it("can iterate over a table", function()
		local base_table = {"a", "b", "c", "d"}
		local num = 1
		for char in fnl._iter("abcd") do
			assert.same(base_table[num], char)
			num = num + 1
		end
	end)
	it("can create correct iterators (_mk_gen())", function()
		local function gen_short_range()
			for i=1, 5 do
				coroutine.yield(i)
			end
		end
		assert.same({1, 2, 3, 4, 5},
			table.from_generator(fnl._mk_gen(gen_short_range)()))
	end)
	it("can map function return values to input stream", function()
		local input = {1, 2, 3, 4, 5}
		local output = {}
		for i, v in ipairs(input) do
			output[i] = v ^ 2
		end
		local function square(n)
			return n ^ 2
		end
		assert.same(output, table.from_generator(fnl.map(square, input)))
	end)
	it("can filter input streams based on function", function()
		local input = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
		local output = {1, nil, 3, nil, 5, nil, 7, nil, 9}
		local find_odds = function(n)
			return n % 2 == 1
		end
		assert.same(output, table.from_generator(fnl.filter(find_odds, input)))
	end)
	it("can reduce input streams based on binary function", function()
		local function add(a, b)
			return a + b
		end
		assert.same(15, fnl.reduce(add, {1, 2, 3, 4, 5}))
	end)
	it("can reduce input streams in a specific order (left/right)", function()
		local function subtract(a, b)
			return a - b
		end
		local nums = {1, 2, 3, 4, 5}
		assert.same(-13, fnl.foldl(subtract, nums))
		assert.same(-5, fnl.foldr(subtract, nums))
	end)
	it("can check for truthiness of values in input streams", function()
		assert.same(true, fnl.any({false, false, false, false, true}))
		assert.same(false, fnl.any({false, false, false, false, false}))
		assert.same(true, fnl.all({true, 1, 0, '', {}}))
		assert.same(false, fnl.all({nil, false}))
		local function is_even(n)
			return n % 2 == 0
		end
		assert.same(true, fnl.any(fnl.map(is_even, itr.range(1, 10))))
		assert.same(false, fnl.any(fnl.map(is_even, itr.range(1, 10, 2))))
		assert.same(true, fnl.all(fnl.map(is_even, itr.range(2, 10, 2))))
		assert.same(false, fnl.all(fnl.map(is_even, itr.range(1, 10, 2))))
	end)
	it("can reduce input streams by adding values", function()
		assert.same(6, fnl.sum({1, 2, 3}))
		assert.same(6, fnl.sum({3, 2, 1}))
	end)
	it("can reduce input streams by subtracting values", function()
		assert.same(-4, fnl.sum({1, 2, 3}, true))
		assert.same(0, fnl.sum({3, 2, 1}, true))
	end)
end)
