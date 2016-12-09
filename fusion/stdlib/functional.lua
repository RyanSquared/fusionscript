local function map(fn, input, ...)
	local _args = {...}
	for k, v in pairs(input) do
		local t0 = {}
		for i, v in ipairs(_args) do
			table.insert(t0, v[k])
		end
		input[k] = fn(v, unpack(t0))
	end
	return input
end

local function filter(fn, input)
	local _to_reduce = {}
	for k, v in pairs(input) do
		if not fn(input) then
			_to_reduce[#_to_reduce + 1] = k
		end
	end
	for k, v in pairs(_to_reduce) do
		input[k] = nil
	end
	return input
end

local function reduce(fn, input, init)
	for k, v in pairs(input) do
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
	for k, v in pairs(input) do
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
	for k, v in pairs(input) do
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

local function pipe(input, ...)
	return reduce(function(a, x) map(x, a) end, {...}, input)
end

return {
	all = all;
	any = any;
	filter = filter;
	foldl = foldl;
	foldr = foldr;
	map = map;
	pipe = pipe;
	reduce = reduce;
}
