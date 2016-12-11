--- Module for iterators and functions that use them
-- @module fusion.stdlib.iterative
local fnl = require("fusion.stdlib.functional")
local table = require("fusion.stdlib.table")

local unpack = unpack or table.unpack -- luacheck: ignore 113

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

--- Loop through an iterable object infinitely, using ipairs as the fallback
-- iterator.
-- @function icycle
-- @tparam iter pattern
-- @see cycle
local function icycle(pattern)
	while true do
		local _iter = iter(pattern, ipairs)
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
	return x + y
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
	for i in xrange(#input) do
		local t0 = {}
		for j in xrange(1, i) do
			t0[j] = input[j]
		end
		coroutine.yield(fnl.reduce(fn, t0))
	end
end

--- Iterate over every iterable object passed.
-- @function chain
-- @tparam iter ... Variable argument of iterable objects
-- @usage for (char in chain("ABCD", "EFGH")) print(char); -- A B C D E F G H
local function chain(...)
	for k, v in pairs({...}) do -- luacheck: ignore 213
		v = iter(v)
		while true do
			local x = {v()}
			if x[1] then
				coroutine.yield(unpack(x))
			else
				break
			end
		end
	end
end

--- Iterate over every iterable object passed, using ipairs as the fallback
-- iterator.
-- @function ichain
-- @tparam iter ... Variable argument of iterable objects
-- @see chain
local function ichain(...)
	for k, v in ipairs({...}) do -- luacheck: ignore 213
		v = iter(v, ipairs)
		while true do
			local x = {v()}
			if x[1] then
				coroutine.yield(unpack(x))
			else
				break
			end
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
	while true do
		local val = input()
		if not val then
			return
		else
			if selectors() then
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
	local _prev, _gen
	for k, _v in iter(input) do -- luacheck: ignore 213
		local v
		if not k then
			v = k
		else
			v = _v
		end
		_gen = {}
		if _prev == nil then
			_prev = v
		end
		if _prev == v then
			table.insert(_gen, v)
		else
			coroutine.yield(_prev, pairs(_gen))
			_prev = v
			_gen = {v}
		end
	end
	coroutine.yield(_prev, pairs(_gen))
end

--- Similar to `groupby()` but use `ipairs()` as the default iterator
-- @function igroupby
-- @tparam iter input
-- @see groupby
local function igroupby(input)
	local _prev, _gen
	for k, v in iter(input, ipairs) do -- luacheck: ignore 213
		_gen = {}
		if _prev == nil then
			_prev = v
		end
		if _prev == v then
			table.insert(_gen, v)
		else
			coroutine.yield(_prev, pairs(_gen))
			_prev = v
			_gen = {v}
		end
	end
	coroutine.yield(_prev, pairs(_gen))
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
		return slice(input, start, #input, 1)
	end
	input = iter(input) -- use 2 to skip first; don't want to chew first value
	for i in xrange(2, start) do -- luacheck: ignore 213
		input()
	end
	for i in xrange(start, stop, step) do -- luacheck: ignore 213
		coroutine.yield(input())
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
	input0, input1 = iter(input0, input1)
	repeat
		local x, y = input0()
		if y then
			x = y
		end
		coroutine.yield(x, input1() or default)
	until not x
end

-- Extended module

local xslice = mk_gen(slice)

--- Return a table based off a slice of the start of a stream.
-- @function head
-- @tparam number n Maximum values to take
-- @tparam iter input
-- @usage print(head("Hello World!"), 5); -- "Hello"
-- @see tail
local function head(n, input)
	return table.from_generator(xslice(input, 1, n))
end

local xcount = mk_gen(count)

--- Repeatedly count upwards and call a function with the value. This function
-- should never return.
-- @function tabulate
-- @tparam function fn
-- @tparam number start Optional value to start at; 0 by default
-- @usage tabulate((n)-> print(n)); -- 0 1 2 3 4 5 6 7...
local function tabulate(fn, start)
	for n in xcount(start or 0) do
		fn(n)
	end
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
-- @usage print(quantify(map((()-> math.random(0, 1)), 1::10), (n)-> n == 1));
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

local xrep = mk_gen(rep)
local xchain = mk_gen(chain)

--- Pad an input stream with nil.
-- @function padnil
-- @tparam iter input
-- @tparam number times Amount of times to pad, default infinite
-- @treturn iter
-- @usage print(k, v for k, v in zip("hello", padnil("hi")));
-- -- ("h", "h") ("e", "i") ("l", nil) ("l", nil) ("o", nil)
local function padnil(input, times)
	return xchain(input, xrep(nil, times))
end

--- Return the dot product of two data streams
-- @function dotproduct
-- @tparam iter t0
-- @tparam iter t1
-- @treturn number
local function dotproduct(t0, t1)
	return fnl.sum(fnl.map((function(a, b) return a * b end), t0,
		t1))
end

return table.from_generator(xchain(fnl.map(mk_gen, {
	count = count;
	cycle = cycle;
	icycle = icycle;
	rep = rep;
	range = range;
	accumulate = accumulate;
	chain = chain;
	ichain = ichain;
	compress = compress;
	groupby = groupby;
	igroupby = igroupby;
	slice = slice;
	zip = zip;
}), {
	head = head;
	tabulate = tabulate;
	tail = tail;
	consume = consume;
	allequal = allequal;
	quantify = quantify;
	padnil = padnil;
	dotproduct = dotproduct;
}))
