--- Module for iterators and functions that use them
-- @module fusion.stdlib.iterative
local fnl = require("fusion.stdlib.functional")
local table = require("fusion.stdlib.table")
local unpack = require("fusion.util").unpack

local iter, mk_gen = fnl._iter, fnl._mk_gen

-- Infinite generators

--- Iterate over a value
-- @lfunction iter
-- @see functional.iter

--- Infinitely count upwards.
-- @function count
-- @tparam number start
-- @tparam number step
-- @usage for (n in count()) {
-- 	print(n)
-- 	if (> n 100) break;
-- }
local function count(start, step)
	if not step then
		return count(start, 1)
	end
	if not start then
		return count(1, step)
	end
	while true do
		coroutine.yield(start)
		start = start + step
	end
end

--- Loop through an iterable object infinitely.
-- @function cycle
-- @tparam iter pattern
-- @usage for (char in cycle("hello")) print(char);
local function cycle(pattern)
	while true do
		local _iter = iter(pattern)
		while true do
			local x = {_iter()}
			if x[1] then
				coroutine.yield(unpack(x))
			else
				break
			end
		end
	end
end

--- Repeatedly yield a value, optionally up to `n` times.
-- @function rep
-- @param element
-- @tparam number n Amount of times to yield (default: infinite)
-- @usage for (fn in rep(get_function())) print(fn);
local function rep(element, n)
	if n then
		for i=1, n do -- luacheck: ignore 213
			coroutine.yield(element)
		end
	else
		while true do
			coroutine.yield(element)
		end
	end
end

-- Terminating generators

--- Return numbers from `start` to `stop`, incrementing by `step`.
-- @function range
-- @tparam number start Default 1
-- @tparam number stop
-- @tparam number step Default 1
-- @usage for (n in range(0, 100, 5)) print(n);
local function range(start, stop, step)
	if not step then
		return range(start, stop, 1)
	elseif not stop then
		return range(1, start, 1)
	else
		for i=start, stop, step do
			coroutine.yield(i)
		end
	end
end

local function add(x, y)
	return x and y and x + y
end

local xrange = mk_gen(range)

--- Return accumulated sums or results of binary function.
-- @function accumulate
-- @tparam iter input
-- @tparam function fn Binary function for reductive accumulation
-- @usage print(x in accumulate(1::5)); -- 1 3 6 10 15
local function accumulate(input, fn)
	if not fn then
		return accumulate(input, add)
	end
	local _iter = iter(input)
	local total = _iter()
	if not total then
		return
	end
	repeat
		coroutine.yield(total)
		total = fn(total, _iter())
	until not total
end

--- Iterate over every iterable object passed.
-- @function chain
-- @tparam iter ... Variable argument of iterable objects
-- @usage for (char in chain("ABCD", "EFGH")) print(char); -- A B C D E F G H
local function chain(...)
	for k, v in pairs({...}) do -- luacheck: ignore 213
		for _k, _v in iter(v) do
			coroutine.yield(_k, _v)
		end
	end
end

--- Return values from input stream based on truthy values in selectors stream.
-- @function compress
-- @tparam iter input
-- @tparam iter selectors
-- @usage for (val in compress({"hello"}, {1, 1, 1, false, 1})) print(val);
-- -- 'helo'
local function compress(input, selectors)
	local _selectors = iter(selectors)
	local _input = iter(input)
	while true do
		local val = _input()
		if not val then
			return
		else
			local a, b = _selectors()
			if b == nil and a or b then
				coroutine.yield(val)
			end
		end
	end
end

--- Squish repeated values based on equality of repeated values.
-- Two values are returned; the value, and an iterator over all values matched.
-- @function groupby
-- @tparam iter input
-- @usage print(group in groupby("ABCCAAAD")); -- A B C A D
local function groupby(input)
	local _prev
	local _gen = {}
	for k, _v in iter(input) do -- luacheck: ignore 213
		local v
		if not _v then
			v = k
		else
			v = _v
		end
		if _prev == nil then
			_prev = v
		end
		if _prev == v then
			table.insert(_gen, v)
		else
			coroutine.yield(_prev, iter(_gen))
			_prev = v
			_gen = {v}
		end
	end
	coroutine.yield(_prev, iter(_gen))
end

--- Return a subsection of an iterable object
-- @function slice
-- @tparam iter input
-- @tparam number start
-- @tparam number stop
-- @tparam number step
-- @usage print(slice("Hello World!", 6)); -- "World!"
local function slice(input, start, stop, step)
	if not step then
		return slice(input, start, stop, 1)
	elseif not stop then
		return slice(input, start, math.huge, 1)
	end
	input = iter(input) -- use 2 to skip first; don't want to chew first value
	for i in xrange(2, start) do -- luacheck: ignore 213
		input()
	end
	for i in xrange(start, stop, step) do -- luacheck: ignore 213
		local x = {input()}
		if not x[1] then
			break
		end
		coroutine.yield(unpack(x))
	end
end

--- Zip two input streams together; table input streams will have their keys
-- discarded.
-- @function zip
-- @tparam iter input0
-- @tparam iter input1
-- @param default Any value; may be null
-- @usage print(key, value for key, value in zip("hi", {"hello", "world"}));
-- -- ("h", "hello") ("i", "world")
local function zip(input0, input1, default)
	input0, input1 = iter(input0), iter(input1)
	repeat
		local ok, x, y = pcall(input0) -- luacheck: ignore 211
		if ok and y then
			x = y
		elseif not ok then
			break
		end
		local ok, val, val2 = pcall(input1) -- luacheck: ignore 411
		if val2 then
			val = val2
		end
		if not ok or not val then
			coroutine.yield(x, default)
		else
			coroutine.yield(x, val)
		end
	until not x
end

-- Extended module

local xslice = mk_gen(slice)

--- Return a table based off a slice of the start of a stream.
-- Does not return n values, but instead will return values after n items are
-- consumed from the stream.
-- @function head
-- @tparam number n Position to start getting results at
-- @tparam iter input
-- @usage print(head("Hello World!"), 5); -- "Hello"
-- @see tail
local function head(n, input)
	-- ::TODO:: queue with size limit to store last values, Pythonic tail()
	return table.from_generator(xslice(input, 1, n))
end

--- Return a table based off a slice of the end of a stream.
-- @function tail
-- @tparam number n Maximum values to take
-- @tparam iter input
-- @usage print(tail("Hello World!"), 6); -- "World!"
-- @see head
local function tail(n, input)
	return table.from_generator(xslice(input, n))
end

--- Run an iterator a certain amount of times.
-- @function consume
-- @tparam iter iterator
-- @tparam number n
-- @treturn iter
-- @usage print(n in consume(1::10, 3)); -- 4 5 6 7 8 9 10
local function consume(iterator, n)
	for i in xrange(n) do -- luacheck: ignore 213
		iterator()
	end
	return iterator
end

local xgroupby = mk_gen(groupby)

--- Return true if all values in `input` stream are true, otherwise false.
-- @function allequal
-- @tparam iter input
-- @treturn bool
-- @usage print(allequal(rep(1, 10))); -- true
local function allequal(input)
	local _iter = xgroupby(input)
	_iter() -- capture first input
	if not _iter() then
		return true
	else
		return false
	end
end

local function truthy(val)
	return not not val
end

--- Return a number incremented for every truthy value in an input stream after
-- a function is applied to it.
-- @function quantify
-- @tparam iter input
-- @tparam function fn
-- @treturn number
-- @usage print(quantify(map((\-> math.random(0, 1)), 1::10), (n)-> n == 1));
local function quantify(input, fn)
	if not fn then
		return quantify(input, truthy)
	end
	local _val = 0
	for _, n in iter(fnl.map(fn, input)) do
		if n then
			_val = _val + 1
		end
	end
	return _val
end

local xchain = mk_gen(chain)

return table.from_generator(xchain(fnl.map(mk_gen, {
	count = count;
	cycle = cycle;
	rep = rep;
	range = range;
	accumulate = accumulate;
	chain = chain;
	compress = compress;
	groupby = groupby;
	slice = slice;
	zip = zip;
}), {
	head = head;
	tail = tail;
	consume = consume;
	allequal = allequal;
	quantify = quantify;
}))
