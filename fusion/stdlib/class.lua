local function class(new, extends, name)
	local base_mt = {
		__index = new;
	}
	setmetatable(new, {
		__tostring = function()
			return name
		end;
		__call = function(...)
			local instance = setmetatable({}, base_mt)
			if new.__init then
				new.__init(instance, ...)
			end
			return instance
		end;
		__index = extends;
	})
	return new
end

return class
