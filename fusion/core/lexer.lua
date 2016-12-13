--- Lex FusionScript files.
-- @module fusion.core.lexer

local re = require("re");

--- @table defs
-- @field true Convert input to `true` boolean
-- @field false Convert input to `false` boolean
-- @field bool Convert input to `defs[input]` - should be `true`/`false`
-- @field numberify Convert input to number via `tonumber`
-- @field err Generate a SyntaxError on current line
-- @field semicolon Generate a SyntaxError for a missing semicolon
local defs = {} -- Definitions for LPeg Regex pattern.
local current_file;

defs['true'] = function() return true end
defs['false'] = function() return false end
defs['bool'] = function(...) return defs[(...)]() end
defs['numberify'] = tonumber

defs.print = print

defs.err = function(pos, char)
	local line = 1
	local start = 1
	local line_start = 0
	while start < pos do
		if current_file:find("^\n", start) then
			line_start = start + 1
			line = line + 1
		end
		start = start + 1
	end
	local input = current_file:sub(pos, pos + 7):gsub("[\r\n\t]", "")
	local errormsg_table = {
		"SyntaxError";
		("Unexpected character on line %d"):format(line);
		("Token: %s"):format(char);
		("Input: >> %q <<"):format(input);
	}
	local errormsg = {
		msg = errormsg_table;
		pos = {
			y = line;
			x = pos - line_start;
		};
		context = current_file:sub(math.max(pos - 2, line_start),
			math.min(pos + 5, current_file:match("()$")));
		quick = "syntax"
	}
	if current_file:match("^[A-Za-z_]", pos) then
		-- found text, match as context
		errormsg.context = current_file:match("[A-Za-z_][A-Za-z0-9_]*", pos);
	end
	setmetatable(errormsg, {
		__tostring = function()
			return table.concat(errormsg_table, "\n")
		end
	})
	error(errormsg, 0)
end

defs.semicolon = function(pos)
	local line = 1
	local start = 1
	local line_start = 0
	while start < pos do
		if current_file:find("^\n", start) then
			line_start = start + 1
			line = line + 1
		end
		start = start + 1
	end
	local input = current_file:sub(math.max(pos - 7, 0), pos):gsub("[\r\n\t]",
		"")
	local errormsg_table = {
		"SyntaxError";
		("Expected semicolon on line %d"):format(line);
		("Input: >> %q <<"):format(input);
	}
	local errormsg = {
		msg = errormsg_table;
		pos = {
			y = line;
			x = pos - line_start - 1;
		};
		context = current_file:sub(pos - 7, pos);
		quick = "semicolon"
	}
	if current_file:match("^[A-Za-z_]", pos) then
		local start_pos = pos
		while current_file:match("^[A-Za-z_]", start_pos) do
			start_pos = start_pos - 1
		end
		errormsg.context = current_file:sub(start_pos, pos)
	end
	setmetatable(errormsg, {
		__tostring = function()
			return table.concat(errormsg_table, "\n")
		end
	})
	error(errormsg, 0)
end

local pattern = re.compile([[
	statement_list <- ws {| ((! '}') rstatement ws)* |}
	statement_block <- {| {:type: '' -> 'block' :} '{' ws statement_list ws '}' |}
	statement <- (
		function_definition
	) / (
		{|{:type: {'using'} :} (space using_name / ws '{' ws
			using_name (ws ',' ws using_name)*
		ws '}' / r) |} /
		assignment /
		function_call /
		return /
		{| {:type: 'break' :} |}
	) (';' / {} -> semicolon) ws / (
		statement_block /
		while_loop /
		numeric_for_loop /
		iterative_for_loop /
		if /
		class
	)
	using_name <- {[A-Za-z]+}
	keyword <- 'local' / 'new' / 'extends' / 'break' / 'return' / 'yield' /
		'true' / 'false' / 'nil' / 'if' / 'else' / 'elseif' / 'while' / 'for' /
		'in' / 'async'
	rstatement <- statement / r
	r <- ({} {.}) -> err
	class <- {| {:is_local: 'local' -> true space :}?
		{:type: 'new' -> 'class' :} space {:name: variable / r :}
		(ws 'extends' ws {:extends: variable / r :})? ws
		'{' ws {| ((! '}') (class_field / r) ws)* |} ws '}'
	|}
	class_field <-
		function_definition /
		{| {:type: '' -> 'class_field' :}
			(
				'[' ws {:name: expression / r :} ws ']' ws ('=' / r) ws (expression
				/ r) ws (';' / r)
				/ {:name: name / r :} ws ('=' / r) ws (expression / r) ws (';' / r)
			)
		|}

	return <- {| {:type: {'return' / 'yield'} :} ws expression_list? |}

	lambda <- {| {:type: '' -> 'lambda' :}
		function_body
	|}
	function_definition <- {| {:type: '' -> 'function_definition' :}
		{:is_async: 'async' -> true space :}? ws
		variable ws function_body -- Do NOT write functions with :
	|}
	function_body <-
		'(' ws function_defined_arguments? ws ')' ws
			({:is_self: '=' -> true :} / '-') '>' ws
			(statement / expression_list / r)
	function_defined_arguments <- {|
		function_argument ((! ')') ws (',' / r) ws function_argument)*
	|}
	function_argument <- {|
		{:name: ((! ")") (name / r)) :} (ws '=' ws {:default: expression / r:})?
	|}

	while_loop <- {| {:type: '' -> 'while_loop' :}
		'while' ws {:condition: expression / r :} ws rstatement
	|}
	iterative_for_loop <- {| {:type: '' -> 'iterative_for_loop' :}
		'for' ws '(' ws (name_list / r) ws 'in' ws (expression / r) ws ')' ws
		rstatement
	|}
	numeric_for_loop <- {| {:type: '' -> 'numeric_for_loop' :}
		'for' ws numeric_for_assignment ws rstatement
	|}
	numeric_for_assignment <- '('
		{:incremented_variable: name / r :} ws '=' ws
		{:start: expression :} ws
		',' ws {:stop: expression :} ws
		(',' ws {:step: expression / r :})?
	')'

	if <- {|
		{:type: 'if' :} ws {:condition: expression / r :} ws rstatement
		{:elseif: {| (ws {|
			'elseif' ws {:condition: expression / r :} ws rstatement
		|})* |} :}
		(ws 'else' ws {:else: rstatement :})?
	|}

	function_call <- {| {:type: '' -> 'function_call' :} (
		variable ({:has_self: ':' -> true :} (variable / r) ws
		{:index_class: ws '<' ws {expression} ws '>' :}? )?
		) ws '(' ws function_call_body? ws ')'
	|}
	function_call_body <- {:generator: {|
		expression (ws 'for' ws (variable_list / r))? ws 'in' ws (expression / r)
	|} :} / function_args
	function_args <- expression_list?

	assignment <- {| {:type: '' -> 'assignment' :}
		(variable_list ws '=' ws (expression_list / r) /
		{:is_local: 'local' -> true :} space (name_list / r) ws ('=' / r) ws
			(expression_list / r))
	|}
	name_list <- {:variable_list: {|
		local_name (ws ',' ws (local_name / r))*
	|} :} / {:variable_list: {|
		{:is_destructuring: '{' -> true :} ws local_name
		(ws ',' ws (local_name / r))* ws '}'
	|} :}
	local_name <- {| {:type: '' -> 'variable' :} name |}
	expression_list <- {:expression_list: {|
		expression (ws ',' ws (expression / r))*
	|} :}

	expression <- value / {| {:type: '' -> 'expression' :}
		'(' ws operator (((! ')') ws expression)+ / r) ws ')'
	|}
	operator <- {:operator:
		'//' /
		'>>' /
		'<<' /
		[=!<>] '=' /
		'&&' /
		'||' /
		'..' /
		[-!#~+*/%^&|<>]
	:}
	value <-
		lambda /
		function_call /
		literal /
		variable
	variable_list <- {:variable_list: {|
		variable (ws ',' ws (variable / r))*
	|} :}
	variable <- {| {:type: '' -> 'variable' :}
		((('@' -> 'self' name? / name) / '(' expression ')') ws ('.' ws (name / r
		) / '[' ws (expression / r) ws ']')*)
	|}
	name <- (! (keyword [^A-Za-z0-9_])) {[A-Za-z_][A-Za-z0-9_]*}

	literal <-
		table /
		{| {:type: '' -> 'vararg' :} { '...' } |} /
		range /
		number /
		string /
		{| {:type: '' -> 'boolean' :}
			('true' / 'false') -> bool
		|} /
		{| {:type: {'nil'} :} |}
	range <- {| {:type: '' -> 'range' :}
		{:start: number :} '::' {:stop: number :} ('::' {:step: number :})?
	|}
	number <- {| {:type: '' -> 'number' :} {:is_negative: '-' -> true :}? (
		base16num /
		base10num
	) |}
	base10num <- {:base: '' -> '10' :} {
		((integer '.' integer) /
		(integer '.') /
		('.' integer) /
		integer) int_exponent?
	} -> numberify
	integer <- [0-9]+
	int_exponent <- [eE] [+-]? integer
	base16num <- {:base: '' -> '16' :} {
		'0' [Xx] [0-9A-Fa-f]+ hex_exponent?
	} -> numberify
	hex_exponent <- [pP] [+-]? integer

	string <- {| dqstring / sqstring / blstring |}
	dqstring <- {:type: '' -> 'dqstring' :} '"' { (('\' .) /
		([^]] .. '\r\n' .. [["]))* } ('"' / r) -- no escape codes in block quotes
	sqstring <- {:type: '' -> 'sqstring' :} "'" { [^]] .. '\r\n' .. [[']* }
		("'" / r)
	blopen <- '[' {:eq: '='* :} '[' ]] .. "'\r'?'\n'?" .. [[
	blclose <- ']' =eq ']'
	blstring <- {:type: '' -> 'blstring' :} blopen {((! blclose) .)*} blclose

	table <- {| {:type: '' -> 'table' :} '{' ws
		(
			table_generator /
			table_field (ws ',' ws table_field)*
		)?
	ws '}' |}
	table_generator <- {| {:type: '' -> 'generator' :}
		table_field (ws 'for' ws (variable_list / r))? ws 'in' ws (expression / r)
	|}
	table_field <-
		{| '[' ws {:index: expression :} ws ']' ws '=' ws (expression / r) |} /
		{| {:name: name :} ws '=' ws (expression / r) |} /
		expression

	ws <-
		('#!' [^]] .. '\r\n' .. [[]*)?
		(%s* '--' [^]] .. '\r\n' .. [[]* ]] .. '\r\n' .. [[?)*
		%s*
	space <- %s+
]], defs);

--- Generate an AST from a file
-- @function lexer:match
-- @tparam string input
-- @treturn table
-- @usage require("pl.pretty").dump(lexer:match("print('hi');"))

return {
	match = function(self, input) -- luacheck: ignore 212
		current_file = input
		return pattern:match(input)
	end
}
