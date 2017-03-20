--- Compile FusionScript AST to Lua code
-- @module fusion.core.parsers.source

local lexer = require("fusion.core.lexer")
local lfs = require("lfs")
local unpack = unpack or table.unpack -- luacheck: ignore 113

local parser = {}
local handlers = {}

--- Initialize a parser state
function parser:new()
	self = setmetatable({}, {__index = parser})
	self.indent = 0
	self.last_node = {}
	return self
end

--- Transform a node using the registered handler.
-- @tparam table node
function parser:transform(node, ...)
	assert(node.type, ("Bad node: %s"):format(tostring(node)))
	assert(handlers[node.type], ("Can't find node handler for (%s)"):format(node.type))
	self.last_node = node
	return handlers[node.type](self, node, ...)
end

--- Add indent to a line of text.
-- @tparam string line
function parser:l(line)
	return ("\t"):rep(self.indent) .. line
end

--- Convert an expression_list field to a transformed list of expressions.
-- @tparam table node
function parser:transform_expression_list(node)
	if not node.expression_list then
		return ""
	end
	local output = {}
	local list = node.expression_list
	for i=1, #list do
		output[#output + 1] = self:transform(list[i])
	end
	return table.concat(output, ", ")
end

--- Convert a variable_list to a transformed list of variable names.
-- @tparam table node
function parser:transform_variable_list(node)
	local output = {}
	local list = node.variable_list
	for i=1, #list do
		output[#output + 1] = self:transform(list[i])
	end
	return table.concat(output, ", ")
end

local _tablegen_level = 0

handlers['nil'] = function() return 'nil' end
handlers['vararg'] = function() return '...' end

local dirs = {
	class = 'local class = require("fusion.stdlib.class")';
	fnl = 'local fnl = require("fusion.stdlib.functional")';
	itr = 'local itr = require("fusion.stdlib.iterable")';
	re = 'local re = require("re")';
	ternary = 'local ternary = require("fusion.stdlib.ternary")';
}

handlers['using'] = function(self, node) -- TODO: no repeat?
	local output = {}
	if node[1] == "*" then
		for _, directive in pairs(dirs) do
			output[#output + 1] = directive
		end
		table.sort(output) -- consistency, helps w/ tests
	else
		for _, directive in ipairs(node) do
			output[#output + 1] = dirs[directive]
		end
	end
	return table.concat(output, self:l"\n")
end

--- Convert a function field in a class to a lambda table assignment.
-- @tparam table node
function parser:transform_class_function(node)
	return {
		name = self:transform(node[1]);
		{
			node[2] or {};
			node[3];
			type = "lambda",
			expression_list = node[1].expression_list;
			is_self = node.is_self;
			is_async = node.is_async;
		}
	}
end

handlers['re'] = function(self, node)
	return 're.compile(' .. ("%q"):format(node[1]) .. ')'
end

handlers['class'] = function(self, node)
	node[1].type = 'table'
	local data = {}
	if node.extends then
		data[1] = "extends = " .. self:transform(node.extends)
	end
	if node.implements then
		data[#data + 1] = "implements = " .. self:transform(node.implements)
	end
	for i, v in ipairs(node[1]) do
		if v.type == "function_definition" then
			node[1][i] = self:transform_class_function(v)
		end
	end
	if node.is_local then
		return ("local %s = class(%s, %s, %q)"):format(self:transform(node.name),
			self:transform(node[1]), "{" .. table.concat(data, ",") .. "}",
			self:transform(node.name))
	else
		return ("%s = class(%s, %s, %q)"):format(self:transform(node.name),
			self:transform(node[1]), "{" .. table.concat(data, ",") .. "}",
			self:transform(node.name))
	end
end

handlers['interface'] = function(self, node)
	local names = node[1]
	for i, v in ipairs(names) do
		names[i] = {name = v, {type = "boolean", true}}
	end
	return self:transform({type="assignment";
		is_local = node.is_local;
		variable_list = {node.name};
		expression_list = {{
			type = "table";
			unpack(names);
		}};
	})
end

handlers['table'] = function(self, node)
	if #node == 0 then
		return '{}'
	elseif node[1].type == "generator" then
		_tablegen_level = _tablegen_level + 1
		local output = {"(function()", self:l("\tlocal _generator_%s = {}"
			):format(_tablegen_level)}
		local generator = node[1]
		if generator[1].index then -- complex
			self.indent = self.indent + 1
			output[#output + 1] = self:l(self:transform({
				generator[2]; -- loop iterator
				{type = "assignment";
					variable_list = {{("_generator_%s"):format(_tablegen_level);
						generator[1].index;
						type = "variable";
					}};
					expression_list = {generator[1][1]}};
				type = "iterative_for_loop";
				variable_list = generator.variable_list;
			}))
			self.indent = self.indent - 1
		else -- simpler
			self.indent = self.indent + 1
			output[#output + 1] = self:l(self:transform({
				generator[2]; -- loop iterator
				{type = "assignment";
					variable_list = {{("_generator_%s"):format(_tablegen_level);
						("#_generator_%s + 1"):format(_tablegen_level);
						type = "variable";
					}};
					expression_list = {generator[1]}};
				type = "iterative_for_loop";
				variable_list = generator.variable_list or {generator[1]};
			}))
			self.indent = self.indent - 1
		end
		output[#output + 1] = (self:l"\treturn _generator_%s"):format(
			_tablegen_level)
		output[#output + 1] = self:l"end)()"
		_tablegen_level = _tablegen_level - 1
		return table.concat(output, "\n")
	end
	local output = {'{'}
	local named = {}
	self.indent = self.indent + 1
	for _, item in ipairs(node) do
		if not item.index and not item.name then
			-- not named, add to normal output
			output[#output + 1] = self:l(self:transform(item)) .. ";"
		else
			if item.index then
				named[#named + 1] = self:l("[%s] = %s;"):format(self:transform(
					item.index), self:transform(item[1]))
			else
				named[#named + 1] = self:l("%s = %s;"):format(item.name,
					self:transform(item[1]))
			end
		end
	end
	for _, item in ipairs(named) do
		output[#output + 1] = item
	end
	self.indent = self.indent - 1
	output[#output + 1] = self:l"}"
	return table.concat(output, "\n")
end

handlers['boolean'] = function(self, node)
	return tostring(node[1])
end

handlers['break'] = function(self, node)
	return node.type
end

handlers['yield'] = function(self, node)
	return ("coroutine.yield(%s)"):format(self:transform_expression_list(node))
end

handlers['return'] = function(self, node)
	return ("return %s"):format(self:transform_expression_list(node))
end

handlers['block'] = function(self, root_node, is_logical)
	local lines = {}
	if not is_logical then
		lines[1] = 'do'
	end
	self.indent = self.indent + 1
	for i, node in ipairs(root_node[1]) do -- luacheck: ignore 213
		lines[#lines + 1] = self:l(self:transform(node))
	end
	self.indent = self.indent - 1
	if not is_logical then
		lines[#lines + 1] = self:l'end'
	end
	return table.concat(lines, '\n')
end

handlers['while_loop'] = function(self, node)
	local output = {"while"}
	output[#output + 1] = self:transform(node.condition)
	if node[1].type ~= "block" then
		output[#output + 1] = self:transform({type = "block", {node[1]}})
	else
		output[#output + 1] = self:transform(node[1])
	end
	return table.concat(output, " ")
end

handlers['numeric_for_loop'] = function(self, node)
	local args = {node.incremented_variable .. "=" ..
	self:transform(node.start), self:transform(node.stop)}
	if node.step then
		args[#args + 1] = self:transform(node.step)
	end
	local output = {"for", table.concat(args, ", ")}
	if node[1].type ~= "block" then
		output[#output + 1] = self:transform({type = "block", {node[1]}})
	else
		output[#output + 1] = self:transform(node[1])
	end
	return table.concat(output, " ")
end

handlers['iterative_for_loop'] = function(self, node)
	local output = {"for", self:transform_variable_list(node), "in",
		self:transform(node[1])}
	if node[2].type ~= "block" then
		output[#output + 1] = self:transform({type = "block", {node[2]}})
	else
		output[#output + 1] = self:transform(node[2])
	end
	return table.concat(output, " ")
end

handlers['if'] = function(self, node)
	local output = {("if %s then"):format(self:transform(node.condition))}
	if node[1].type == "block" then
		output[#output + 1] = handlers['block'](self, node[1], true)
	else
		output[#output + 1] = self:l("\t" .. self:transform(node[1]))
	end
	for _, blk in ipairs(node['elseif']) do
		output[#output + 1] = self:l("elseif %s then"):format(self:transform(
			blk.condition))
		if blk[1].type == "block" then
			output[#output + 1] = handlers['block'](self, blk[1], true)
		else
			output[#output + 1] = self:l("\t" .. self:transform(blk[1]))
		end
	end
	if node["else"] then
		output[#output + 1] = self:l("else")
		if node["else"].type == "block" then
			output[#output + 1] = handlers['block'](self, node["else"], true)
		else
			output[#output + 1] = self:l("\t" .. self:transform(node["else"]))
		end
	end
	output[#output + 1] = self:l"end"
	return table.concat(output, "\n")
end

handlers['function_definition'] = function(self, node)
	local is_interpretable_raw = true
	for _, name in ipairs(node[1]) do
		-- if type is not string, issue with `function x.y.z()` syntax
		-- can't do function a[b] in Lua, for example
		if type(name) ~= "string" then
			is_interpretable_raw = false
		end
	end
	local name = self:transform(node[1])
	local output = {}
	local header = {}
	if is_interpretable_raw then
		if node.is_local then
			header[1] = ("local function %s("):format(name)
		else
			header[1] = ("function %s("):format(name)
		end
	else
		header[1] = ("%s = function("):format(name)
	end
	local defaults, args = {}, {}
	if node.is_self then
		args[1] = "self"
	end
	if node[2] and not node[2].type then -- empty parameter list
		for _, arg in ipairs(node[2]) do
			if arg.default then
				defaults[arg.name] = self:transform(arg.default)
			end
			args[#args + 1] = arg.name
		end
	end
	header[2] = table.concat(args, ", ") .. ")"
	output[1] = table.concat(header)
	self.indent = self.indent + 1
	for arg_name, default in pairs(defaults) do
		output[#output + 1] = self:l(("if not %s then"):format(arg_name))
		output[#output + 1] = self:l(("\t%s = %s"):format(arg_name, default))
		output[#output + 1] = self:l"end"
	end
	self.indent = self.indent - 1
	if node.expression_list then
		output[#output + 1] = self:l"\treturn " ..
			self:transform_expression_list(node)
	else
		if node.is_async then
			-- wrap block in `return coroutine.wrap(function()`
			self.indent = self.indent + 1
			output[#output + 1] = self:l"return coroutine.wrap(function()"
		end
		if node[#node].type == "block" then
			output[#output + 1] = handlers['block'](self, node[#node], true)
		else
			output[#output + 1] = self:l"\t" .. self:transform(node[#node])
		end
		if node.is_async then
			-- wrap block in `return coroutine.wrap(function()`
			output[#output + 1] = self:l"end)"
			self.indent = self.indent - 1
		end
	end
	output[#output + 1] = self:l"end"
	return table.concat(output, "\n")
end

handlers['lambda'] = function(self, node)
	local output = {}
	local defaults, args = {}, {}
	if node.is_self then
		args[1] = "self"
	end
	if node[1] and not node[1].type then -- empty parameter list
		for _, arg in ipairs(node[1]) do
			if arg.default then -- keep for compat with class methods!
				defaults[arg.name] = self:transform(arg.default)
			end
			args[#args + 1] = arg.name
		end
	end
	output[1] = "(function(" .. table.concat(args, ", ") .. ")"
	self.indent = self.indent + 1
	for name, default in pairs(defaults) do
		output[#output + 1] = self:l(("if not %s then"):format(name))
		output[#output + 1] = self:l(("\t%s = %s"):format(name, default))
		output[#output + 1] = self:l"end"
	end
	self.indent = self.indent - 1
	if node.expression_list then
		output[#output + 1] = self:l"\treturn " ..
			self:transform_expression_list(node)
	else
		if node.is_async then
			-- wrap block in `return coroutine.wrap(function()`
			self.indent = self.indent + 1
			output[#output + 1] = self:l"return coroutine.wrap(function()"
		end
		if node[#node].type == "block" then
			output[#output + 1] = handlers['block'](self, node[#node], true)
		else
			self.indent = self.indent + 1
			output[#output + 1] = self:l(self:transform(node[#node]))
			self.indent = self.indent - 1
		end
		if node.is_async then
			-- wrap block in `return coroutine.wrap(function()`
			output[#output + 1] = self:l"end)"
			self.indent = self.indent - 1
		end
	end
	output[#output + 1] = self:l"end)"
	return table.concat(output, "\n")
end

local operator_transformations = {
	["!="] = "~=";
	["&&"] = "and";
	["||"] = "or";
	["!"] = "not "; -- use space to avoid collisions such as `notx` from `!x`
}

local ternary_operator_transformations = {
	['?:'] = function(condition, is_if, is_else)
		return ("(ternary(%s, %s, %s))"):format(condition, is_if, is_else)
	end
}

handlers['expression'] = function(self, node)
	if operator_transformations[node.operator] then
		node.operator = operator_transformations[node.operator]
	end
	if #node > 2 then -- TODO chain operators
		local expr = {}
		for i = 1, #node do
			expr[#expr + 1] = self:transform(node[i])
		end
		return ternary_operator_transformations[node.operator](unpack(expr))
	elseif #node == 2 then
		return ("(%s %s %s)"):format(self:transform(node[1]), node.operator,
			self:transform(node[2]))
	elseif #node == 1 then
		return ("(%s%s)"):format(node.operator, self:transform(node[1]))
	end
end

handlers['number'] = function(self, node)
	local is_negative = node.is_negative and "-" or ""
	if node.base == "10" then
		if math.floor(node[1]) == node[1] then
			return is_negative .. ("%i"):format(node[1])
		else
			return is_negative .. ("%f"):format(node[1])
		end
	else
		return is_negative .. ("0x%x"):format(node[1])
	end
end

handlers['range'] = function(self, node)
	local output = {
		"itr.range(";
		self:transform(node.start);
		", ";
		self:transform(node.stop);
	}
	if node.step then
		output[5] = ", "
		output[6] = self:transform(node.step)
	end
	output[#output + 1] = ")"
	return table.concat(output)
end

local des_num = 0

handlers['assignment'] = function(self, node)
	local output = {}
	if node.is_local then
		output[1] = "local "
	end
	if node.is_nil then
		local names = {}
		for i, v in ipairs(node) do -- luacheck: ignore 213
			table.insert(names, self:transform(v))
		end
		table.insert(output, table.concat(names, ", "))
		return table.concat(output)
	elseif node.variable_list.is_destructuring then
		local expression = self:transform(node.expression_list[1])
		local name
		if node.expression_list[1].type == "variable" and
			not node.expression_list[1][2] then -- no indexing
			name = ("_des_%s_%i"):format(expression, des_num)
		else
			name = "_des_" .. tostring(des_num)
		end
		des_num = des_num + 1
		local last = {} -- capture all last values
		table.insert(output, 1, ("local %s = %s\n"):format(name, expression))
		if node.variable_list.is_destructuring == "table" then
			for i, v in ipairs(node.variable_list) do
				local value = self:transform(v)
				last[#last + 1] = name .. "." .. value
				output[#output + 1] = value
				if node.variable_list[i + 1] then
					output[#output + 1] = ', '
				end
			end
		elseif node.variable_list.is_destructuring == "array" then
			local counter = 0
			for i, v in ipairs(node.variable_list) do
				local value = self:transform(v)
				counter = counter + 1
				last[#last + 1] = ("%s[%i]"):format(name, counter)
				output[#output + 1] = value
				if node.variable_list[i + 1] then
					output[#output + 1] = ', '
				end
			end
		end
		output[#output + 1] = " = "
		output[#output + 1] = table.concat(last, ', ')
		des_num = des_num - 1
		return table.concat(output)
	end
	output[#output + 1] = self:transform_variable_list(node)
	output[#output + 1] = " = "
	output[#output + 1] = self:transform_expression_list(node)
	return table.concat(output)
end

handlers['function_call'] = function(self, node)
	if node.generator then
		return self:transform {
			node.generator[1];
			{type = "function_call";
				node[1];
				has_self = node.has_self;
				index_class = node.index_class;
				expression_list = node.generator.expression_list or
					node.generator.variable_list;
			};
			type = "iterative_for_loop"; -- `in` without `for` only 1 var   V
			variable_list = node.generator.variable_list
		}
	else
		local name
		if node.has_self then
			if node.index_class then
				node.expression_list = node.expression_list or {}
				table.insert(node.expression_list, 1, node[1])
				node[1] = {type = "variable", node.index_class}
				name = self:transform(node[1]) .. "." .. node.has_self
			else
				name = self:transform(node[1]) .. ":" .. node.has_self
			end
		elseif #node[1] == 2 and node.is_method then
			name = node[1][1] .. ":" .. node[1][2]
		else
			name = self:transform(node[1])
		end
		return name .. "(" .. self:transform_expression_list(node) .. ")"
	end
end

handlers['variable'] = function(self, node)
	local name = {}
	if type(node[1]) == "table" then
		name[1] = "(" .. self:transform(node[1]) .. ")"
	else
		name[1] = node[1]
	end
	for i=2, #node do
		if type(node[i]) == "string" then
			if node[i]:match("^[_A-Za-z][_A-Za-z0-9]*$") then
				name[#name + 1] = "." .. node[i]
			else
				name[#name + 1] = "[" .. node[i] .. "]"
			end
		else
			name[#name + 1] = "[" .. self:transform(node[i]) .. "]"
		end
	end
	return table.concat(name)
end

handlers['sqstring'] = function(self, node)
	return ("%q"):format(node[1]:gsub("\\", "\\\\"))  -- \ is ignored in '' strings
end

handlers['dqstring'] = function(self, node)
	return ('"%s"'):format(node[1])
end

handlers['blstring'] = function(self, node)
	local eq = ("="):rep(#node.eq)
	return ("[%s[%s]%s]"):format(eq, node[1], eq)
end

--- Convert an iterator returning FusionScript chunks to Lua code.
-- Do not use this function directly to compile code.
-- @tparam table in_values Table of values to compile
-- @tparam function output_stream Repeatedly called with generated code
function parser.compile(in_values, output_stream)
	local parser_state = parser:new()
	for _, input in ipairs(in_values) do
		output_stream(parser_state:transform(input))
	end
end

--- Read FusionScript code from a file and return output.
-- @tparam string file File to read input from
-- @treturn string Lua code
function parser.read_file(file)
	local append, output
	output = {}
	append = function(line) output[#output + 1] = line end
	local source_file = assert(io.open(file))
	local line = source_file:read("*l")
	if line and not line:match("^#!") then
		source_file:seek("set")
	end
	local node = lexer:match(source_file:read("*a"))
	source_file:close()
	parser.compile(node, append)
	return table.concat(output, "\n") .. "\n" -- EOL at EOF
end

local loadstring = loadstring or load -- luacheck: ignore 113

--- Load FusionScript code from a file and return a function to run the code.
-- @tparam string file
-- @treturn function Loaded FusionScript code
function parser.load_file(file)
	local content = parser.read_file(file)
	return assert(loadstring(content))
end

--- Load and run FusionScript code from a file
-- @tparam string file
function parser.do_file(file)
	return (parser.load_file(file)())
end

--- Find a module in the package path and return relevant information.
-- Returns `nil` and an error message if not found.
-- Do not use this function by itself; use `parser.inject_loader()`.
-- @tparam string module_name
-- @treturn function Closure to return loaded module
-- @treturn string Path to loaded file
function parser.search_for(module_name)
	local module_path = module_name:gsub("%.", "/")

	local file_path
	for _, path in ipairs(package.fusepath_t) do
		file_path = path:gsub("?", module_path)
		if lfs.attributes(file_path) then
			return function() return parser.do_file(file_path) end, file_path
		end
	end
	local msg = {}
	for _, path in ipairs(package.fusepath_t) do
		msg[#msg + 1] = ("\tno file %q"):format(path:gsub("?", module_path))
	end
	return "\n" .. table.concat(msg, "\n")
end

--- Inject `parser.search_for` into the `require()` searchers list.
-- @treturn boolean False if loader already found
-- @usage parser.inject_loader(); print(require("test_module"))
-- -- Attempts to load a FusionScript `test_module` package
function parser.inject_loader()
	for _, loader in ipairs(package.loaders or package.searchers) do
		if loader == parser.search_for then
			return false
		end
	end
	table.insert(package.loaders or package.searchers, 2, parser.search_for)
	return true
end

if not package.fusepath then
	local paths = {}
	for path in package.path:gmatch("[^;]+") do
		local match = path:match("^(.+)%.lua$")
		if match then
			if match:sub(1, 2) == "./" then
				paths[#paths + 1] = "./vendor/" .. match:sub(3) .. ".fuse"
			end
			paths[#paths + 1] = match .. ".fuse"
		end
	end
	package.fusepath = table.concat(paths, ";")
	package.fusepath_t = paths
end

return parser
