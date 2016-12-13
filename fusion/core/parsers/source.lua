--- Compile FusionScript AST to Lua code
-- @module fusion.core.parsers.source

local lexer = require("fusion.core.lexer")
local lfs = require("lfs")

local indent = 0
local parser = {}
local handlers = {}
local last_node = {} -- luacheck: ignore 231

--- Transform a node using the registered handler.
-- @tparam table node
local function transform(node, ...)
	assert(node.type, ("Bad node: %s"):format(node))
	assert(handlers[node.type], ("Can't find node handler for (%s)"):format(node.type))
	last_node = node
	return handlers[node.type](node, ...)
end

--- Add indent to a line of text.
-- @tparam string line
local function l(line)
	return ("\t"):rep(indent) .. line
end

--- Convert an expression_list field to a transformed list of expressions.
-- @tparam table node
local function transform_expression_list(node)
	if not node.expression_list then
		return ""
	end
	local output = {}
	local list = node.expression_list
	for i=1, #list do
		output[#output + 1] = transform(list[i])
	end
	return table.concat(output, ",")
end

--- Convert a variable_list to a transformed list of variable names.
-- @tparam table node
local function transform_variable_list(node)
	local output = {}
	local list = node.variable_list
	for i=1, #list do
		output[#output + 1] = transform(list[i])
	end
	return table.concat(output, ",")
end

local _tablegen_level = 0

handlers['nil'] = function() return 'nil' end
handlers['vararg'] = function(node) return '...' end -- luacheck: ignore 212

handlers['using'] = function(node)
	local output = {}
	for _, directive in ipairs(node) do
		if directive == "class" then
			output[#output + 1] = 'local class = require("fusion.stdlib.class")'
		elseif directive == "fnl" then
			output[#output + 1] = 'local fnl = require("fusion.stdlib.functional")'
		elseif directive == "itr" then
			output[#output + 1] = 'local itr = require("fusion.stdlib.iterable")'
		end
	end
	return table.concat(output, l"\n")
end

--- Convert a function field in a class to a lambda table assignment.
-- @tparam table node
local function transform_class_function(node)
	return {
		name = transform(node[1]);
		{
			node[2] or {};
			node[3];
			type = "lambda",
			expression_list = node[1].expression_list;
			is_self = node.is_self;
		}
	}
end

handlers['class'] = function(node)
	node[1].type = 'table'
	if not node.extends then
		node.extends = {type = "nil"}
	end
	for i, v in ipairs(node[1]) do
		if v.type == "function_definition" then
			node[1][i] = transform_class_function(v)
		end
	end
	if node.is_local then
		return ("local %s = class(%s, %s, %q)"):format(transform(node.name),
			transform(node[1]), transform(node.extends), transform(node.name))
	else
		return ("%s = class(%s, %s, %q)"):format(transform(node.name),
			transform(node[1]), transform(node.extends), transform(node.name))
	end
end

handlers['table'] = function(node)
	if #node == 0 then
		return '{}'
	elseif node[1].type == "generator" then
		_tablegen_level = _tablegen_level + 1
		local output = {"(function()", l("\tlocal _generator_%s = {}"):format(
			_tablegen_level)}
		local generator = node[1]
		if generator[1].index then -- complex
			indent = indent + 1
			output[#output + 1] = l(transform({
				generator[2]; -- loop iterator
				{type = "assignment";
					variable_list = {{("_generator_%s"):format(_tablegen_level);
						generator[1].index;
						type = "variable";
					}};
					expression_list = {generator[1][1]};
				};
				type = "iterative_for_loop";
				variable_list = generator.variable_list;
			}))
			indent = indent - 1
		else -- simpler
			indent = indent + 1
			output[#output + 1] = l(transform({
				generator[2]; -- loop iterator
				{type = "assignment";
					variable_list = {{("_generator_%s"):format(_tablegen_level);
						("#_generator_%s + 1"):format(_tablegen_level);
						type = "variable";
					}};
					expression_list = {generator[1]};
				};
				type = "iterative_for_loop";
				variable_list = generator.variable_list or {generator[1]};
			}))
			indent = indent - 1
		end
		output[#output + 1] = (l"\treturn _generator_%s"):format(_tablegen_level)
		output[#output + 1] = l"end)()"
		_tablegen_level = _tablegen_level - 1
		return table.concat(output, "\n")
	end
	local output = {'{'}
	local named = {}
	indent = indent + 1
	for _, item in ipairs(node) do
		if not item.index and not item.name then
			-- not named, add to normal output
			output[#output + 1] = l(transform(item)) .. ";"
		else
			if item.index then
				named[#named + 1] = l("[%s] = %s;"):format(transform(item.index),
					transform(item[1]))
			else
				if item.name:match("^[A-Za-z_][A-Za-z0-9_]*$") then
					named[#named + 1] = l("%s = %s;"):format(item.name,
						transform(item[1]))
				else
					named[#named + 1] = l("[%q] = %s;"):format(item.name,
						transform(item[1]))
				end
			end
		end
	end
	for _, item in ipairs(named) do
		output[#output + 1] = item
	end
	indent = indent - 1
	output[#output + 1] = "}"
	return table.concat(output, "\n")
end

handlers['boolean'] = function(node)
	return tostring(node[1])
end

handlers['break'] = function(node)
	return node.type
end

handlers['yield'] = function(node)
	return ("coroutine.yield(%s)"):format(transform_expression_list(node))
end

handlers['return'] = function(node)
	return ("return %s"):format(transform_expression_list(node))
end

handlers['block'] = function(root_node, is_logical) -- ::TODO:: check for block
	local lines = {}
	if not is_logical then
		lines[1] = 'do'
	end
	indent = indent + 1
	for i, node in ipairs(root_node[1]) do -- luacheck: ignore 213
		lines[#lines + 1] = l(transform(node))
	end
	indent = indent - 1
	if not is_logical then
		lines[#lines + 1] = l'end'
	end
	return table.concat(lines, '\n')
end

handlers['while_loop'] = function(node)
	local output = {"while"}
	output[#output + 1] = transform(node.condition)
	if node[1].type ~= "block" then
		output[#output + 1] = transform({type = "block", {node[1]}})
	else
		output[#output + 1] = transform(node[1])
	end
	return table.concat(output, " ")
end

handlers['numeric_for_loop'] = function(node)
	local output = {"for", node.incremented_variable, "=", transform(
		node.start), ",", transform(node.stop)}
	if node.step then
		output[#output + 1] = ","
		output[#output + 1] = transform(node.step)
	end
	if node[1].type ~= "block" then
		output[#output + 1] = transform({type = "block", {node[1]}})
	else
		output[#output + 1] = transform(node[1])
	end
	return table.concat(output, " ")
end

handlers['iterative_for_loop'] = function(node)
	local output = {"for", transform_variable_list(node), "in",
		transform(node[1])}
	if node[2].type ~= "block" then
		output[#output + 1] = transform({type = "block", {node[2]}})
	else
		output[#output + 1] = transform(node[2])
	end
	return table.concat(output, " ")
end

handlers['if'] = function(node)
	local output = {("if %s then"):format(transform(node.condition))}
	if node[1].type == "block" then
		output[#output + 1] = handlers['block'](node[1], true)
	else
		output[#output + 1] = l("\t" .. transform(node[1]))
	end
	for _, blk in ipairs(node['elseif']) do
		output[#output + 1] = l("elseif %s then"):format(transform(
			blk.condition))
		if blk.type == "block" then
			output[#output + 1] = handlers['block'](blk[1], true)
		else
			output[#output + 1] = l("\t" .. transform(blk[1]))
		end
	end
	if node["else"] then
		output[#output + 1] = l("else")
		if node["else"].type == "block" then
			output[#output + 1] = handlers['block'](node["else"], true)
		else
			output[#output + 1] = l("\t" .. transform(node["else"]))
		end
	end
	output[#output + 1] = l"end"
	return table.concat(output, "\n")
end

handlers['function_definition'] = function(node)
	local is_interpretable_raw = true
	for _, name in ipairs(node[1]) do
		-- if type is not string, issue with `function x.y.z()` syntax
		-- can't do function a[b] in Lua, for example
		if type(name) ~= "string" then
			is_interpretable_raw = false
		end
	end
	local name = transform(node[1])
	local output = {}
	local header = {}
	if is_interpretable_raw then
		header[1] = ("function %s("):format(name)
	else
		header[1] = ("%s = function("):format(name)
	end
	local defaults, args = {}, {}
	if node.is_self then
		args[1] = "self"
	end
	if not node[2].type then -- empty parameter list
		for _, arg in ipairs(node[2]) do
			if arg.default then
				defaults[arg.name] = transform(arg.default)
			end
			args[#args + 1] = arg.name
		end
	end
	header[2] = table.concat(args, ", ") .. ")"
	output[1] = table.concat(header)
	indent = indent + 1
	for arg_name, default in pairs(defaults) do
		output[#output + 1] = l(("if not %s then"):format(arg_name))
		output[#output + 1] = l(("\t%s = %s"):format(arg_name, default))
		output[#output + 1] = l"end"
	end
	indent = indent - 1
	if node.expression_list then
		output[#output + 1] = l"\treturn " .. transform_expression_list(node)
	else
		if node.is_async then
			-- wrap block in `return coroutine.wrap(function()`
			indent = indent + 1
			output[#output + 1] = l"return coroutine.wrap(function()"
		end
		if node[#node].type == "block" then
			output[#output + 1] = handlers['block'](node[#node], true)
		else
			output[#output + 1] = l(transform(node[#node]))
		end
		if node.is_async then
			-- wrap block in `return coroutine.wrap(function()`
			output[#output + 1] = l"end)"
			indent = indent - 1
		end
	end
	output[#output + 1] = l"end"
	return table.concat(output, "\n")
end

handlers['lambda'] = function(node)
	local output = {}
	local defaults, args = {}, {}
	if node.is_self then
		args[1] = "self"
	end
	if not node[1].type then -- empty parameter list
		for _, arg in ipairs(node[1]) do
			if arg.default then
				defaults[arg.name] = transform(arg.default)
			end
			args[#args + 1] = arg.name
		end
	end
	output[1] = "(function(" .. table.concat(args, ", ") .. ")"
	indent = indent + 1
	for name, default in pairs(defaults) do
		output[#output + 1] = l(("if not %s then"):format(name))
		output[#output + 1] = l(("\t%s = %s"):format(name, default))
		output[#output + 1] = l"end"
	end
	indent = indent - 1
	if node.expression_list then
		output[#output + 1] = l"\treturn " .. transform_expression_list(node)
	else
		if node[#node].type == "block" then
			output[#output + 1] = handlers['block'](node[#node], true)
		else
			output[#output + 1] = l("\t" .. transform(node[#node]))
		end
	end
	output[#output + 1] = l"end)"
	return table.concat(output, "\n")
end

local operator_transformations = {
	["!="] = "~=";
	["&&"] = "and";
	["||"] = "or";
	["!"] = "not "; -- rare case; usually symbols instead of kw,
}

handlers['expression'] = function(node)
	if operator_transformations[node.operator] then
		node.operator = operator_transformations[node.operator]
	end
	if #node > 2 then -- TODO chain operators
		local expr = {}
		for i = 1, #node do
			expr[#expr + 1] = transform(node[i])
		end
		error("too many values in expression", '(' .. node.operator .. ' ' ..
			table.concat(node, ' ') ')')
	elseif #node == 2 then
		return ("(%s %s %s)"):format(transform(node[1]), node.operator,
			transform(node[2]))
	elseif #node == 1 then
		return ("(%s%s)"):format(node.operator, transform(node[1]))
	end
end

handlers['number'] = function(node)
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

handlers['range'] = function(node)
	local output = {
		"itr.range(";
		transform(node.start);
		", ";
		transform(node.stop);
	}
	if node.step then
		output[5] = ", "
		output[6] = transform(node.step)
	end
	output[#output + 1] = ")"
	return table.concat(output)
end

local des_num = 0

handlers['assignment'] = function(node)
	local output = {}
	if node.is_local then
		output[1] = "local "
	end
	if node.variable_list.is_destructuring then
		local name = "_des_" .. tostring(des_num)
		des_num = des_num + 1
		local expression = transform(node.expression_list[1])
		local last = {} -- capture all last values
		table.insert(output, 1, ("local %s = %s\n"):format(name, expression))
		for i, v in ipairs(node.variable_list) do
			local value = transform(v)
			last[#last + 1] = name .. "." .. value
			output[#output + 1] = value
			if node.variable_list[i + 1] then
				output[#output + 1] = ', '
			end
		end
		output[#output + 1] = " = "
		output[#output + 1] = table.concat(last, ', ')
		des_num = des_num - 1
		return table.concat(output)
	end
	output[#output + 1] = transform_variable_list(node) -- ::TODO::
	output[#output + 1] = " = "
	output[#output + 1] = transform_expression_list(node) -- ::TODO::
	return table.concat(output)
end

handlers['function_call'] = function(node)
	if node.generator then
		return transform {
			node.generator[2];
			{type = "function_call";
				node[1];
				node[2];
				has_self = node.has_self;
				index_class = node.index_class;
				expression_list = {node.generator[1]};
			};
			type = "iterative_for_loop"; -- `in` without `for` only 1 var   V
			variable_list = node.generator.variable_list or {node.generator[1]}
		}
	else
		local name
		if node.has_self then
			if node.index_class then
				node.expression_list = node.expression_list or {}
				table.insert(node.expression_list, 1, node[1])
				node[1] = {type = "variable", node.index_class}
				name = transform(node[1]) .. "." .. transform(node[2])
			else
				name = transform(node[1]) .. ":" .. transform(node[2])
			end
		else
			name = transform(node[1])
		end
		if node.expression_list then
			return name .. "(" .. transform_expression_list(node) .. ")"
		else
			return name .. "()"
		end
	end
end

handlers['variable'] = function(node)
	local name = {}
	if type(node[1]) == "table" then
		name[1] = "(" .. transform(node[1]) .. ")"
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
			name[#name + 1] = "[" .. transform(node[i]) .. "]"
		end
	end
	return table.concat(name)
end

handlers['sqstring'] = function(node)
	return ("%q"):format(node[1]:gsub("\\", "\\\\"))  -- \ is ignored in '' strings
end

handlers['dqstring'] = function(node)
	return ('"%s"'):format(node[1])
end

handlers['blstring'] = function(node)
	local eq = ("="):rep(node.eq)
	return ("[%s[%s]%s]"):format(eq, node[1], eq)
end

--- Convert an iterator returning FusionScript chunks to Lua code.
-- Do not use this function directly to compile code.
-- @tparam function input_stream Used as an iterator to retrieve code
-- @tparam function output_stream Repeatedly called with generated code
function parser.compile(input_stream, output_stream)
	for input in input_stream do
		output_stream(transform(input))
	end
end

--- Read FusionScript code from a file and return or print output.
-- @tparam string file File to read input from
-- @tparam boolean dump Boolean to print output instead of return (optional)
-- @treturn string Lua code
function parser.read_file(file, dump)
	local append, output
	if dump then
		append = print
	else
		output = {}
		append = function(line) output[#output + 1] = line end
	end
	local source_file = io.open(file)
	if not source_file:read("*l"):match("^#!") then
		source_file:seek("set")
	end
	local node = lexer:match(source_file:read("*a"))
	source_file:close()
	parser.compile(coroutine.wrap(function()
		for key, value in pairs(node) do -- luacheck: ignore 213
			coroutine.yield(value)
		end
	end), append)
	return table.concat(output, "\n")
end

--- Load FusionScript code from a file and return a function to run the code.
-- @tparam string file
-- @treturn function Loaded FusionScript code
function parser.load_file(file)
	local content = parser.read_file(file)
	if loadstring then -- luacheck: ignore 113
		return assert(loadstring(content)) -- luacheck: ignore 113
	else
		return assert(load(content))
	end
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
	return nil, "\n" .. table.concat(msg, "\n")
end

--- Inject `parser.search_for` into the `require()` searchers list.
-- @treturn boolean False if loader already found
-- @usage parser.inject_loader(); print(require("test_module"))
-- -- Attempts to load a FusionScript `test_module` package
function parser.inject_loader()
	for _, loader in ipairs(package.searchers) do
		if loader == parser.search_for then
			return false
		end
	end
	package.searchers[2] = parser.search_for
	return true
end

if not package.fusepath then
	local paths = {}
	for path in package.path:gmatch("[^;]+") do
		local match = path:match("^(.+)%.lua$")
		if match then
			paths[#paths + 1] = match .. ".fuse"
		end
	end
	package.fusepath = table.concat(paths, ";")
	package.fusepath_t = paths
end

return parser
