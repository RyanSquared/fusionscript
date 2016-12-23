--- Contains a function to create classes
-- @module fusion.stdlib.class

--- Generate a new class from a given class.
-- @function class
-- @tparam table new Base class table
-- @tparam table extends Class to use as index class
-- @tparam string name Name of class
-- @treturn class
local function class(new, data, name)
	local extends, implements = data.extends, data.implements
	local base_mt = {
		__index = new;
		__tostring = function(self)
			return (name .. "(" .. table.concat(self.__args, ", ") .. ")")
		end;
	}
	if implements then
		-- check for all values implemented
		-- error otherwise
		for k in pairs(implements) do
			if k:sub(1, 1) ~= "_" then
				-- is not metavalue
				if extends then
					assert(new[k] or extends[k])
				else
					assert(new[k], ("missing value %s for class %s"):format(
						k, name))
				end
			end
		end
	end
	setmetatable(new, {
		__tostring = function()
			return name
		end;
		__call = function(this_class, ...) -- luacheck: ignore 212
			local instance = setmetatable({
				__class = new;
				__super = extends;
				__impl = implements;
			}, base_mt)
			instance.__args = {}
			for i, v in ipairs({...}) do
				local _type = type(v)
				if _type == "string" then
					instance.__args[i] = ("%q"):format(v)
				else
					instance.__args[i] = tostring(v)
				end
			end
			instance.__class = new
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
