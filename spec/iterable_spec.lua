local itr = require("fusion.stdlib.iterable")
local table = require("fusion.stdlib.table")

describe("iterable", function()
	it("has a working counter", function()
		local ex_1 = {1, 2, 3, 4, 5}
		local ex_2 = {2, 4, 6, 8, 10}
		local counter = itr.count()
		for i, v in ipairs(ex_1) do -- luacheck: ignore 213
			assert.same(v, counter())
		end
		local counter_even = itr.count(2, 2)
		for i, v in ipairs(ex_2) do -- luacheck: ignore 213
			assert.same(v, counter_even())
		end
	end)
	it("can repeat over a pattern", function()
		local output = {"a", "b", "c", "d", "a", "b", "c", "d"}
		local repeater = itr.cycle("abcd")
		for i=1, 8 do
			assert.same(output[i], repeater())
		end
	end)
	it("can repeat an element (almost) infinitely", function()
		local counter = 0
		for x in itr.rep('a') do
			assert.same('a', x)
			counter = counter + 1
			if counter > 100 then
				break
			end
		end
		for x in itr.rep('b', 99) do
			assert.same('b', x)
			assert.same(true, counter > 0)
			counter = counter - 1
		end
	end)
	it("can produce a range of numbers like a numeric for loop", function()
		assert.same({1, 2, 3, 4, 5}, table.from_generator(itr.range(5)))
		assert.same({1, 2, 3, 4, 5}, table.from_generator(itr.range(1, 5)))
		assert.same({5, 4, 3, 2, 1}, table.from_generator(itr.range(5, 1, -1)))
		assert.same({2, 4, 6, 8, 10}, table.from_generator(itr.range(2, 10, 2)))
	end)
	it("can accumulate values over an iteration", function()
		assert.same({}, table.from_generator(itr.accumulate(function() return nil
			end))) -- quick check to get coverage over nil accumulations
		assert.same({1, 3, 6, 10, 15}, table.from_generator(itr.accumulate(
			itr.range(1, 5))))
	end)
	it("can chain multiple streams together", function()
		assert.same({1, 2, 3, 4}, table.from_generator(itr.chain(itr.range(2),
			itr.range(3, 4))))
	end)
	it("can compress values of one stream based on truthiness of another stream",
		function()
		assert.same({1, 2, 4, 5}, table.from_generator(itr.compress(itr.range(1,
			5), {true, true, false, true, true})))
	end)
	it("can group values by equality", function()
		local grouped = itr.groupby("AABBCCCDA")
		local test = {}
		for name, iter in grouped do
			table.insert(test, {name, table.concat(table.from_generator(iter))})
		end
		assert.same({{"A", "AA"}, {"B", "BB"}, {"C", "CCC"}, {"D", "D"}, {"A",
			"A"}}, test)

		local grouped_2 = itr.groupby(table.from_generator(("AABBCCCDA"):gmatch(
			"."))) -- test for grouping in tables as well as streams
		local test_2 = {}
		for name, iter in grouped_2 do
			table.insert(test_2, {name, table.concat(table.from_generator(iter))})
		end
		assert.same({{"A", "AA"}, {"B", "BB"}, {"C", "CCC"}, {"D", "D"}, {"A",
			"A"}}, test_2)
	end)
	it("can create a slice of an iterable object", function()
		assert.same({3, 4, 5, 6, 7}, table.from_generator(itr.slice(itr.range(1,
			10), 3, 7)))
	end)
	it("can zip two streams together", function()
		assert.same({9, 8, 7, 6, 5}, table.from_generator(itr.zip(itr.range(1, 5),
			itr.range(9, 5, -1))))
		assert.same({9, 8, 7, 6, 5}, table.from_generator(itr.zip(itr.range(1, 5),
			table.from_generator(itr.range(9, 5, -1)))))
		assert.same({9, 8, 7, 6, 5}, table.from_generator(itr.zip(
			table.from_generator(itr.range(1, 5)), table.from_generator(itr.range(
			9, 5, -1)))))
	end)
	it("can pad values with zipped streams", function()
		assert.same({9, 8, 7, true, true}, table.from_generator(itr.zip(
			itr.range(1, 5), itr.range(9, 7, -1), true)))
	end)
end)

describe("iterable extension", function()
	it("can get head of stream", function()
		assert.same("Hello", table.concat(itr.head(5, "Hello World!")))
	end)
	it("can get tail of stream", function() -- ::TODO:: fix in iterable lib
		assert.same("World!", table.concat(itr.tail(7, "Hello World!")))
	end)
	it("can consume a section of an iterator", function()
		local gen = itr.range(10)
		itr.consume(gen, 5)
		assert.same({6, 7, 8, 9, 10}, table.from_generator(gen))
	end)
	it("can determine if all values are equal in a generator", function()
		assert.same(true, itr.allequal(("A"):rep(50)))
		assert.same(false, itr.allequal(("B"):rep(50) .. "A" .. ("B"):rep(50)))
		assert.same(true, itr.allequal(itr.chain(("A"):rep(5), {"A", "A"})))
		-- chaining data streams returning similar values, like the above line,
		-- works! :D
	end)
	it("can quantify the truthiness of an iterator", function()
		assert.same(5, itr.quantify({true, true, false, true, false, 1, 0}))
	end)
end)
