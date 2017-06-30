--- Utility libraries for FusionScript internal methods
-- @module fusion.util

--- Wrap `unpack()` and `table.unpack()`
-- @function unpack

return {
	unpack = unpack or table.unpack -- luacheck: ignore
}
