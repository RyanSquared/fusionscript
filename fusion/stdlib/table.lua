-- luacheck: ignore 122

function table.copy(t0)
	local t1 = {}
	for k, v in pairs(t0) do
		t1[k] = v
	end
	return t1
end

function table.from_generator(iterable, ...)
	local t0 = {}
	for k, v in iterable, ... do
		if v then
			t0[k] = v
		else
			t0[#t0 + 1] = k
		end
	end
	return t0
end

function table.join(t0, t1)
	local t2 = {}
	for k, v in pairs(t0) do
		t2[k] = v
	end
	for k, v in pairs(t1) do
		t2[k] = v
	end
	return t2
end

local _old_sort = table.sort

function table.sort(t, ...)
	_old_sort(t, ...)
	return t
end

return table
