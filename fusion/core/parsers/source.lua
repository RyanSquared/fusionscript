local lexer = require("fusion.core.lexer")

local parser = {}
local handlers = {}
local last_node = {}

function transform(node, ...)
	assert(handlers[node.type], ("Can't find node handler for (%s)"):format(node.type))
	last_node = node
	return handlers[node.type](node, ...)
end

function transform_expression_list(node)
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

function transform_variable_list(node)
	local output = {}
	local list = node.variable_list
	for i=1, #list do
		output[#output + 1] = transform(list[i])
	end
	return table.concat(output, ",")
end

local _tablegen_level = 0

handlers['nil'] = function() return 'nil' end

handlers['table'] = function(node)
	if node[1].type == "generator" then
		_tablegen_level = _tablegen_level + 1
		local output = {"(function()", ("local _generator_%s = {}"):format(
			_tablegen_level)}
		local generator = node[1]
		if generator[1].index then -- complex
			output[#output + 1] = transform({
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
			})
		else -- simpler
			output[#output + 1] = transform({
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
			})
		end
		output[#output + 1] =( "return _generator_%s"):format(_tablegen_level)
		output[#output + 1] = "end)()"
		_tablegen_level = _tablegen_level - 1
		return table.concat(output, "\n")
	end
	local output = {'{'}
	local named = {}
	for _, item in ipairs(node) do
		if not item.index and not item.name then
			-- not named, add to normal output
			output[#output + 1] = transform(item) .. ";"
		else
			if item.index then
				named[#named + 1] = ("[%s] = %s;"):format(transform(item.index),
					transform(item[1]))
			else
				if item.name:match("^[A-Za-z_][A-Za-z0-9_]*$") then
					named[#named + 1] = ("%s = %s;"):format(item.name,
						transform(item[1]))
				else
					named[#named + 1] = ("[%q] = %s;"):format(item.name,
						transform(item[1]))
				end
			end
		end
	end
	for _, item in ipairs(named) do
		output[#output + 1] = item
	end
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
	for i, node in ipairs(root_node[1]) do
		lines[#lines + 1] = transform(node)
	end
	if not is_logical then
		lines[#lines + 1] = 'end'
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
	local output = {("if (%s) then"):format(transform(node.condition))}
	if node[1].type == "block" then
		output[#output + 1] = ha1dlers['block'](node[1], true)
	else
		output[#output + 1] = transform(node[1])
	end
	output[#output + 1] = "end"
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
	for _, arg in ipairs(node[2]) do
		if arg.default then
			defaults[arg.name] = transform(arg.default)
		end
		args[#args + 1] = arg.name
	end
	header[2] = table.concat(args, ", ") .. ")"
	output[1] = table.concat(header)
	for name, default in pairs(defaults) do
		output[#output + 1] = ("if not %s then"):format(name)
		output[#output + 1] = ("%s = %s"):format(name, default)
		output[#output + 1] = "end"
	end
	if node.expression_list then
		output[#output + 1] = "return " .. transform_expression_list(node)
	else
		if node.is_async then
			-- wrap block in `return coroutine.wrap(function()`
			output[#output + 1] = "return coroutine.wrap(function()"
		end
		if node[#node].type == "block" then
			output[#output + 1] = handlers['block'](node[#node], true)
		else
			output[#output + 1] = transform(node[#node])
		end
		if node.is_async then
			-- wrap block in `return coroutine.wrap(function()`
			output[#output + 1] = "end)"
		end
	end
	output[#output + 1] = "end"
	return table.concat(output, "\n")
end

local operator_transformations = {
	["!="] = "~="
}

handlers['expression'] = function(node)
	local output = {}
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
	is_negative = node.is_negative and "-" or ""
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

handlers['assignment'] = function(node)
	local output = {}
	if node.is_local then
		output[1] = "local "
	end
	if node.variable_list.is_destructuring then
		local expression = transform(node.expression_list[1])
		local last = {} -- capture all last values
		for i, v in ipairs(node.variable_list) do
			local value = transform(v)
			last[#last + 1] = expression .. "." .. value
			output[#output + 1] = value
			if node.variable_list[i + 1] then
				output[#output + 1] = ','
			end
		end
		output[#output + 1] = " = "
		output[#output + 1] = table.concat(last, ',')
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
			variable_list = {node.generator[1]};
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
	local name = {node[1]}
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

function parser.compile(input_stream, output_stream)
	for input in input_stream do
		output_stream(transform(input))
	end
end

function parser.read_file(file, dump)
	local append, output
	if dump then
		append = print
	else
		output = {}
		append = function(line) output[#output + 1] = line end
	end
	local source_file = io.open(file)
	local node = lexer:match(source_file:read("*a"))
	source_file:close()
	parser.compile(coroutine.wrap(function()
		for key, value in pairs(node) do
			coroutine.yield(value)
		end
	end), append)
	return table.concat(output, "\n")
end

function parser.load_file(file)
	local content = parser.read_file(file)
	if loadstring then
		return assert(loadstring(content))
	else
		return assert(load(content))
	end
end

function parser.do_file(file)
	return (parser.load_file(file)())
end

return parser
