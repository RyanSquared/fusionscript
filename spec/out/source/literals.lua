local a = 1
local b = 1.500000
local c = 250000000
local d = 5500
local e = 0xdeadbeef
local f = 0x20
local a = "tes\\\\t"
local b = "tes\t"
local c = "tes\\t"
local d = [[this is a long string
]]
local a = true
local b = false
local c = (not true)
local d = (not false)
local a = nil
local a = {
	1;
	b = 2;
	[c] = 3;
	["d"] = 4;
	[{}] = 5;
	[true] = 6;
	[false] = 7;
}
local array = (function()
	local _generator_1 = {}
	for k in ipairs({
		1;
		2;
		3;
		4;
		5;
	}) do
		_generator_1[#_generator_1 + 1] = k
	end
	return _generator_1
end)()
local transformed_array = (function()
	local _generator_1 = {}
	for k in ipairs({
		1;
		2;
		3;
		4;
		5;
	}) do
		_generator_1[#_generator_1 + 1] = (2 ^ k)
	end
	return _generator_1
end)()
local copy_transformed_array = (function()
	local _generator_1 = {}
	for k, v in pairs(transformed_array) do
		_generator_1[k] = v
	end
	return _generator_1
end)()
local a = re.compile("{[A-Za-z]+}")
