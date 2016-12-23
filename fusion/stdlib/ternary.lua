--- A single function to act as a ternary, right to left
-- @module fusion.stdlib.ternary

--- Return one of two values based on initial condition
-- @function ternary
-- @tparam boolean condition
-- @param is_if Value to return if condition is truthy
-- @param is_else Value to return if condition is not truthy
return function(condition, is_if, is_else)
	if condition then
		return is_if
	else
		return is_else
	end
end
