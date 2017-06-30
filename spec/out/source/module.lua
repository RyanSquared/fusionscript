-- :module: example.module.name
_ENV = setmetatable({}, {__index = _G})
return _ENV
