local lexer = require("fusion.core.lexer")

local parser = {}
local handlers = {}
local indentation_level = 0

function transform(node, ...)
	assert(handlers[node[1]], ("Can't find node handler for (%s)"):format(node[1]))
	return handlers[node[1]](node, ...)
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
	return node[2]
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
	indentation_level = indentation_level + 1
	for i, node in ipairs(root_node[2]) do
		lines[#lines + 1] = ("\t"):rep(indentation_level) .. transform(node)
	end
	if not is_logical then
		lines[#lines + 1] = 'end'
	end
	indentation_level = indentation_level - 1
	return table.concat(lines, '\n')
end

handlers['while_loop'] = function(node)
	local output = {"while"}
	output[#output + 1] = transform(node.condition)
	if node[2][1] ~= "block" then
		output[#output + 1] = transform({"block", {node[2]}})
	else
		output[#output + 1] = transform(node[2])
	end
	return table.concat(output, " ")
end

handlers['expression'] = function(node)
	local output = {}
	if #node > 3 then
		local expr = {}
		for i = 2, #node do
			expr[#expr + 1] = transform(node[i])
		end
		error("too many values in expression", '(' .. node.operator .. ' ' ..
			table.concat(node, ' ') ')')
	elseif #node == 3 then
		return ("(%s %s %s)"):format(transform(node[2]), node.operator,
			transform(node[3]))
	elseif #node == 2 then
		return ("(%s%s)"):format(node.operator, transform(node[2]))
	end
end

handlers['number'] = function(node)
	if node.type == "base10" then
		if math.floor(node[2]) == node[2] then
			return ("%i"):format(node[2])
		else
			return ("%f"):format(node[2])
		end
	else
		return ("0x%x"):format(node[2])
	end
end

handlers['assignment'] = function(node)
	local output = {}
	if node[2].is_local then
		output[1] = "local "
	end
	if node[2].variable_list.is_destructuring then
		-- ::TODO:: change node[1] to node in lexer
		local expression = transform(node[2].expression_list[1])
		local last = {} -- capture all last values
		for i, v in ipairs(node[2].variable_list) do
			local value = transform(v)
			last[#last + 1] = expression .. "." .. value
			output[#output + 1] = value
			if node[2].variable_list[i + 1] then
				output[#output + 1] = ','
			end
		end
		output[#output + 1] = " = "
		output[#output + 1] = table.concat(last, ',')
		return table.concat(output)
	end
	output[#output + 1] = transform_variable_list(node[2]) -- ::TODO::
	output[#output + 1] = " = "
	output[#output + 1] = transform_expression_list(node[2]) -- ::TODO::
	return table.concat(output)
end

handlers['function_call'] = function(node)
	local name = transform(node[2])
	if node.expression_list then -- has expressions, return with expressions
		return name .. "(" .. transform_expression_list(node) .. ")"
	else
		return name .. "()"
	end
end

handlers['variable'] = function(node)
	local name = {node[2]}
	for i=3, #node do
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
	return "'" .. node[2]:gsub("\\", "\\\\") .. "'"  -- \ is ignored in '' strings
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
	return output
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