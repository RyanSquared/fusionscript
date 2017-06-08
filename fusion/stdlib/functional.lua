--- Module for "functional" iterators and functions.
-- @module fusion.stdlib.functional
local unpack = require("fusion.util").unpack

--- Iterate over a table's keys and values
-- @tparam table input
-- @treturn iter Initialized iterator
local function _pairs(input)
	return coroutine.wrap(function()
		for k, v in pairs(input) do
			coroutine.yield(k, v)
		end
	end)
end

--- Return an iterator over a value if possible or the value passed.
-- Possible value types can be strings and any object with __pairs or __ipairs
-- metadata.
-- @tparam table input Table to iterate over (can also be iterator function)
-- @tparam function iterator Table iterator to use (`pairs()` by default)
-- @treturn function
local function iter(input, ...)
	local iterator = ...
	if type(input) == "function" then
		return input, ...
	elseif type(input) == "string" then
		return input:gmatch(".")
	else
		if not iterator then
			return iter(input, _pairs)
		end
		return iterator(input)
	end
end

--- Make an iterator (or 'generator') from a function.
-- @tparam function fn
-- @treturn function Wrapped coroutine
local function mk_gen(fn)
	return function(...)
		local a = {...}
		return coroutine.wrap(function()
			return fn(unpack(a))
		end)
	end
end

--- Apply a function to one or more input streams, and return the values.
-- @function map
-- @tparam function fn
-- @tparam iter input
-- @treturn iter Initialized iterator
-- @usage print(x in map((\v -> (^ v 2)), 1::10)); -- squares
local function map(fn, input)
	for k, v in iter(input) do
		if v then
			coroutine.yield(k, fn(v))
		else
			coroutine.yield(fn(k))
		end
	end
end

--- Return values in an input stream if an applied function returns true.
-- @function filter
-- @tparam function fn
-- @tparam iter input Iterable object
-- @treturn iter Initialized iterator
-- @usage print(x in filter((\v -> (== (% v 2) 1)), 1::10)); -- odds
local function filter(fn, input)
	for k, v in iter(input) do -- luacheck: ignore 213
		if fn(k, v) then
			coroutine.yield(k, v)
		end
	end
end

--- Return a value from a function applied to all values of an input stream.
-- @function reduce
-- @tparam function fn
-- @tparam iter input Iterable object
-- @param init Initial value (will use first value of stream if not supplied)
-- @usage print(reduce((\x, y -> (?: (> x y) x y)), {5, 2, 7, 9, 1})); -- math.max()
local function reduce(fn, input, init)
	for k, v in iter(input) do -- luacheck: ignore 213
		if init == nil then
			init = v
		else
			init = assert(fn(init, v))
		end
	end
	return init
end

--- Does the same thing as `reduce`, but operates on ordered sequences.
-- This function should only be used on numeric tables or indexable streams.
-- Use `foldl()` or `foldr()` for convenience instead of this function unless
-- you need control over the exact sequence.
-- @function fold
-- @tparam number start
-- @tparam number stop
-- @tparam number step
-- @tparam function fn
-- @param input Numerically indexable object
-- @param init Initial value (will use first value in input if not supplied)
-- @see reduce
local function fold(start, stop, step, fn, input, init)
	for i=start, stop, step do
		if not init then
			init = input[i]
		else
			init = assert(fn(init, input[i]))
		end
	end
	return init
end

--- Fold starting from the first value of input to the last value of input.
-- @function foldl
-- @tparam function fn
-- @param input Numerically indexable object
-- @param init Initial value (will use first value in input if not supplied)
-- @see fold, foldr, reduce
local function foldl(fn, input, init)
	return fold(1, #input, 1, fn, input, init)
end

--- Fold starting from the last value of input to the first value of input.
-- @function foldr
-- @tparam function fn
-- @param input Numerically indexable object
-- @param init Initial value (will use last value in input if not supplied)
-- @see fold, foldl, reduce
local function foldr(fn, input, init)
	return fold(#input, 1, -1, fn, input, init)
end

--- Return the boolean form of a value. False and nil return false, otherwise
-- true is returned.
-- @param val Value to convert to boolean value (optionally nil)
-- @treturn boolean
local function truthy(val)
	return not not val
end

--- Return true if any returned value from an input stream are truthy,
-- otherwise false.
-- @function any
-- @tparam function fn
-- @tparam iter input
-- @treturn boolean
-- @usage print(any({nil, true, false})); -- true
local function any(fn, input)
	if not fn or not input then
		return any(truthy, fn or input)
	end
	for k, v in iter(input) do -- luacheck: ignore 213
		if v ~= nil and fn(v) then
			return true
		elseif v == nil and fn(k) then
			return true
		end
	end
	return false
end

--- Return true if all returned values from an input stream are truthy.
-- @function all
-- @tparam function fn
-- @tparam iter input
-- @treturn boolean
-- @usage print(all(chain(1::50, {false}))); -- false
local function all(fn, input)
	if not fn or not input then
		return all(truthy, fn or input)
	end
	for k, v in iter(input) do -- luacheck: ignore 213
		if v ~= nil and not fn(v) then
			return false
		elseif v == nil and not fn(k) then
			return false
		end
	end
	return true
end

--- Return a sum of all values in a stream.
-- @function sum
-- @tparam iter input
-- @tparam boolean negative optional; returns a difference instead if true
-- @treturn number
-- @usage print(sum(1::50));
local function sum(input, negative)
	if negative then
		return reduce(function(a, b) return a - b end, input)
	else
		return reduce(function(a, b) return a + b end, input)
	end
end

return {
	_pairs = _pairs;
	_iter = iter;
	_mk_gen = mk_gen;
	all = all;
	any = any;
	filter = mk_gen(filter);
	foldl = foldl;
	foldr = foldr;
	map = mk_gen(map);
	reduce = reduce;
	sum = sum;
}
