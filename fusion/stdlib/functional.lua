local unpack = unpack or table.unpack -- luacheck: ignore 113

local function iter(input, iterator)
	if type(input) == "function" then
		return input
	elseif type(input) == "string" then
		return input:gmatch(".")
	else
		if not iterator then
			return iter(input, pairs)
		end
		return iterator(input)
	end
end

local function mk_gen(fn)
	return function(...)
		local a = {...}
		return coroutine.wrap(function()
			return fn(unpack(a))
		end)
	end
end

local function map(fn, input, ...)
	local _args = {...}
	for i, v in ipairs(_args) do
		_args[i] = iter(v)
	end
	for k, v in iter(input) do
		local t0 = {}
		for i, _v in ipairs(_args) do -- luacheck: ignore 213
			table.insert(t0, _v())
		end
		input[k] = fn(v, unpack(t0))
		coroutine.yield(k, fn(v, unpack(t0)))
	end
end

local function filter(fn, input)
	for k, v in iter(input) do -- luacheck: ignore 213
		if fn(v) then
			coroutine.yield(k, v)
		end
	end
end

local function reduce(fn, input, init)
	for k, v in iter(input) do -- luacheck: ignore 213
		if not init then
			init = v
		else
			init = assert(fn(init, v))
		end
	end
	return init
end

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

local function foldl(fn, input, init)
	return fold(1, #input, 1, fn, input, init)
end

local function foldr(fn, input, init)
	return fold(#input, 1, -1, fn, input, init)
end

local function truthy(val)
	return not not val
end

local function any(fn, input)
	if not fn then
		return any(input, truthy)
	end
	for k, v in pairs(input) do -- luacheck: ignore 213
		if fn(v) then
			return true
		end
	end
	return false
end

local function all(fn, input)
	if not fn then
		return all(input, truthy)
	end
	for k, v in pairs(input) do -- luacheck: ignore 213
		if not fn(v) then
			return false
		end
	end
	return true
end

local function sum(input)
	local _val = 0
	for _, v in pairs(input) do
		_val = _val + assert(tonumber(v))
	end
end

local xreduce, xmap = mk_gen(reduce), mk_gen(map)

local function pipe(input, ...)
	return xreduce(function(a, x) xmap(x, a) end, {...}, input)
end

return {
	all = all;
	any = any;
	filter = mk_gen(filter);
	foldl = foldl;
	foldr = foldr;
	map = mk_gen(map);
	pipe = pipe;
	reduce = reduce;
	sum = sum;
}
