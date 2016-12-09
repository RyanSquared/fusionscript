local fnl = require("fusion.stdlib.functional")
local table = require("fusion.stdlib.table")

local unpack = unpack or table.unpack -- luacheck: ignore 113

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
	if not start then
		return count(1, step)
	end
	while true do
		coroutine.yield(start)
		start = start + step
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
	for k, v in pairs({...}) do -- luacheck: ignore 213
		if type(v) == "function" then
			for val in v do
				coroutine.yield(val)
			end
		else
			for _k, _v in pairs(v) do -- luacheck: ignore 213
				coroutine.yield(_v)
			end
		end
	end
end

local function ichain(...)
	for i, v in ipairs({...}) do -- luacheck: ignore 213
		for _i, _v in ipairs(v) do -- luacheck: ignore 213
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

local function groupby(input)
	local _prev, _gen
	for k, v in pairs(input) do -- luacheck: ignore 213
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

local function igroupby(input)
	local _prev, _gen
	for k, v in ipairs(input) do -- luacheck: ignore 213
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

local xslice = mk_gen(slice)

local function take(n, input)
	return table.from_generator(xslice(input, n))
end

local xcount = mk_gen(count)

local function tabulate(fn, start)
	for n in xcount(start or 0) do
		fn(n)
	end
end

local function tail(n, input)
	return table.from_generator(xslice(input, n))
end

local function consume(iterator, n)
	for i in xrange(n) do -- luacheck: ignore 213
		iterator()
	end
	return iterator
end

local function nth(n, input, default)
	return input[n] or default
end

local xgroupby = mk_gen(groupby)

local function all_equal(input)
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

local function quantify(input, fn)
	if not fn then
		return quantify(input, truthy)
	end
	local _val = 0
	for _, n in pairs(fnl.map(fn, table.copy(input))) do
		if n then
			_val = _val + 1
		end
	end
	return _val
end

local xrep = mk_gen(rep)
local xchain = mk_gen(chain)

local function padnil(input)
	return xchain(input, xrep(nil))
end

local function dotproduct(t0, t1)
	return fnl.sum(fnl.map((function(a, b) return a * b end), t0, t1))
end

return table.join(fnl.map(mk_gen, {
	count = count;
	cycle = cycle;
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
	take = take;
	tabulate = tabulate;
	tail = tail;
	consume = consume;
	nth = nth;
	all_equal = all_equal;
	quantify = quantify;
	padnil = padnil;
	dotproduct = dotproduct;
})
