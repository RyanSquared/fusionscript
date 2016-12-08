local re = require("re");

local defs = {}
local current_file;

defs['true'] = function() return true end
defs['false'] = function() return false end
defs['bool'] = function(...) return defs[(...)]() end
defs['numberify'] = tonumber

defs.print = print

local balanced_borders = re.compile [=[
	match <- { parens / square / curly }
	parens <- "(" ([^()] / parens)^-10 ")"?
	square <- "[" ([^][] / square)^-10 "]"?
	curly <- "{" ([^{}] / parens)^-10 "}"?
]=]

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
		pos = {
			y = line;
			x = pos - line_start;
		};
		context = current_file:sub(pos, pos + 5);
		quick = "syntax"
	}
	if current_file:match("^[A-Za-z_]", pos) then
		-- found text, match as context
		errormsg.context = current_file:match("[A-Za-z_][A-Za-z0-9_]*", pos);
	elseif current_file:match("^%[%]{}%(%)", pos-30) then
		-- found brackets, match text up to newline as context
		errormsg.context = balanced_borders:match(current_file:sub(pos, pos+30));
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
		function_call /
		assignment /
		return /
		{| {:type: 'break' :} |}
	) ws ';' ws / (
		statement_block /
		while_loop /
		numeric_for_loop /
		iterative_for_loop /
		function_definition /
		if /
		class
	)
	rstatement <- statement / r
	r <- ({} {.}) -> err
	class <- {| {:type: 'new' -> 'class' :} space {:name: name / r :}
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
		expression (ws 'for' ws variable_list / r)? ws 'in' ws (expression / r)
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
	name <- {[A-Za-z_][A-Za-z0-9_]*}

	literal <-
		table /
		{| {:type: '' -> 'vararg' :} { '...' } |} /
		number /
		string /
		{| {:type: '' -> 'boolean' :}
			('true' / 'false') -> bool
		|} /
		{| {:type: {'nil'} :} |}
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
	blstring <- {:type: '' -> 'blstring' :} '[' {:eq: '='* :} '[' blclose
	blclose <- ']' =eq ']' / . blclose / r

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
		{| '[' ws {:index: variable :} ws ']' ws '=' ws (expression / r) |} /
		{| {:name: name :} ws '=' ws (expression / r) |} /
		expression

	ws <- %s* ('--' [^]] .. '\r\n' .. [[]* ]] .. '\r\n' .. [[?)? %s*
	space <- %s+
]], defs);

return {
	match = function(self, input) -- luacheck: ignore 212
		current_file = input
		return pattern:match(input)
	end
}
