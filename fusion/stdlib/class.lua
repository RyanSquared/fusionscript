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
	new.__index = new;
	new.__tostring = new.__tostring or function(self)
		local args = {}
		for _=1, self.__argc do
			local arg = self.__args[_]
			local _type = type(arg)
			if _type == "string" then
				args[_] = ("%q"):format(arg)
			else
				args[_] = tostring(arg)
			end
		end
		return (name .. "(" .. table.concat(args, ", ") .. ")")
	end;
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
			}, new)
			instance.__args = {...}
			instance.__argc = select('#', ...)
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
