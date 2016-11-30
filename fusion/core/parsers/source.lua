local lexer = require("fusion.core.lexer")

local parser = {}
local handlers = {}

function transform(node, ...)
	assert(handlers[node.type], ("Can't find node handler for (%s)"):format(node.type))
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

handlers['boolean'] = function(node)
	return node[1]
end

handlers['break'] = function(node)
	return node[1]
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
	for i, node in ipairs(root_node[2]) do
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

handlers['expression'] = function(node)
	local output = {}
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
	if node.type == "base10" then
		if math.floor(node[1]) == node[1] then
			return ("%i"):format(node[1])
		else
			return ("%f"):format(node[1])
		end
	else
		return ("0x%x"):format(node[1])
	end
end

handlers['assignment'] = function(node)
	local output = {}
	if node.is_local then
		output = "local "
	end
	if node[1].variable_list.is_destructuring then
		-- ::TODO:: change node[1] to node in lexer
		local expression = transform(node[2].expression_list[1])
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
	local name = transform(node[1])
	if node.expression_list then -- has expressions, return with expressions
		return name .. "(" .. transform_expression_list(node) .. ")"
	else
		return name .. "()"
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
	local content = table.concat(parser.read_file(file))
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
