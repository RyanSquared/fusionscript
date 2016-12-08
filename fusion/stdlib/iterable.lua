local fnl = require("fusion.stdlib.functional")

local function mk_gen(fn)
	return function(...)
		local a = {...}
		return coroutine.wrap(function()
			return fn(unpack(a))
		end)
	end
end

-- Infinite generators

local function count(start, step)
	if not step then
		return count(start, 1)
	end
	while true do
		start = start + step
		coroutine.yield(start)
	end
end

local function cycle(pattern, is_ipairs)
	local pairs_statement = is_ipairs and ipairs or pairs
	while true do
		for k, v in pairs_statement(pattern) do
			coroutine.yield(k, v)
		end
	end
end

local function rep(element, n)
	if n then
		for i=1, n do
			coroutine.yield(element)
		end
	else
		while true do
			coroutine.yield(element)
		end
	end
end

-- Terminating generators

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

local function chain(...)
	for k, v in pairs({...}) do
		for _k, _v in pairs(v) do
			coroutine.yield(_v)
		end
	end
end

local function ichain(...)
	for i, v in ipairs({...}) do
		for _i, _v in ipairs(v) do
			coroutine.yield(_v)
		end
	end
end

local function compress(input, selectors)
	-- must use ipairs and numeric input/selectors
	for i=1, math.max(#input, #selectors) do
		if not input[i] then
			return
		else
			if selectors[i] then
				coroutine.yield(input[i])
			end
		end
	end
end

local function slice(input, start, stop, step)
	if not step then
		return slice(input, start, stop, 1)
	elseif not stop then
		return slice(input, start, #input, 1)
	end
	for i in xrange(start, stop, step) do
		coroutine.yield(input[i])
	end
end

local function zip(input0, input1, default)
	for i=1, math.max(#input0, #input1) do
		coroutine.yield(input0[i], input1[i] or default)
	end
end

-- Extended module

return fnl.map(mk_gen, {
	count = count;
	cycle = cycle;
	rep = rep;
	range = range;
	accumulate = accumulate;
	chain = chain;
	ichain = ichain;
	compress = compress;
	slice = slice;
	zip = zip;
})
