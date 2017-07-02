-- :module: example.module.name
_ENV = setmetatable({}, {__index = _G})
local _des_0 = require("stdlib.error")
local BaseError, Error, error_lib_assert = _des_0.BaseError, _des_0.Error, _des_0.assert
return _ENV
