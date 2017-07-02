describe("lexer", function()
	local lexer = require("fusion.core.parser")
	it("can send appropriate errors", function()

		local err_syntax = assert.errors(function() lexer:match("fail") end)
		assert.same("syntax", err_syntax.quick)
		assert.same("fail", err_syntax.context)
		assert.is_not_same("table", tostring(err_syntax):sub(1, 5))

		local err_sc = assert.errors(function() lexer:match("fail()") end)
		assert.same("semicolon", err_sc.quick)
		assert.same("fail()", err_sc.context)
		assert.is_not_same("table", tostring(err_sc):sub(1, 5))

		local err_syntax_2 = assert.errors(function()
				lexer:match("test();\nasdf") end)
		assert.same("syntax", err_syntax_2.quick)
		assert.same("asdf", err_syntax_2.context)
		assert.is_not_same("table", tostring(err_syntax_2):sub(1, 5))

		local err_sc_2 = assert.errors(function()
				lexer:match("test();\nreturn") end)
		assert.same(err_sc_2.quick, "semicolon")
		assert.same(err_sc_2.context:sub(-6), "return")
		assert.is_not_same("table", tostring(err_sc_2):sub(1, 5))

	end)

	it("can parse break statements", function()
		assert.same({{pos = 1, type = "break"}}, lexer:match("break;"))
	end)

	it("can parse simple yield statements", function()
		assert.same({{pos = 1, type = "yield"}}, lexer:match("yield;"))
	end)

	it("can parse complex yield statements", function()
		assert.same({{pos = 1, type = "yield",
			expression_list = {
				{type = "variable", "a"},
				{type = "variable", "b"}
			}
		}}, lexer:match("yield a, b;"))
	end)

	it("can parse simple return statements", function()
		assert.same({{pos = 1, type = "return"}}, lexer:match("return;"))
	end)

	it("can parse complex return statements", function()
		assert.same({{pos = 1, type = "return",
			expression_list = {
				{type = "variable", "a"},
				{type = "variable", "b"}
			}
		}}, lexer:match("return a, b;"))
	end)

	it("can parse local nil assignment", function()
		assert.same({{pos = 1, type = "assignment",
			{type = "variable", "a"},
			{type = "variable", "b"},
			is_local = true,
			is_nil = true
		}}, lexer:match("local (a, b);"))
	end)

	it("can parse basic assignment", function()
		assert.same({{pos = 1, type = "assignment",
				variable_list = {
					{type = "variable", "a"}
				},
				expression_list = {
					{type = "variable", "b"}
				}
			}}, lexer:match("a = b;"))
	end)

	it("can parse local assignment", function()
		assert.same({{pos = 1, type = "assignment",
				variable_list = {
					{type = "variable", "a"}
				},
				expression_list = {
					{type = "variable", "b"}
				},
				is_local = true
			}}, lexer:match("local a = b;"))
	end)

	it("can parse self indexing", function()
		assert.same({{pos = 1, type = "assignment",
				variable_list = {
					{type = "variable", "a"}
				},
				expression_list = {
					{type = "variable", "self", "b"}
				},
				is_local = true
			}}, lexer:match("local a = @b;"))
	end)

	it("can parse complex self indexing", function()
		assert.same({{pos = 1, type = "assignment",
				variable_list = {
					{type = "variable", "a"}
				},
				expression_list = {
					{type = "variable", "self", {type = "variable", "b"}}
				},
				is_local = true
			}}, lexer:match("local a = @[b];"))
	end)

	it("can parse assigning to self", function()
		assert.same({{pos = 1, type = "assignment",
				variable_list = {
					{type = "variable", "self", "a"}
				},
				expression_list = {
					{type = "variable", "b"}
				}
			}}, lexer:match("@a = b;"))
	end)

	it("can parse destructuring tables to local assignment", function()
		assert.same({{pos = 1, type = "assignment",
				variable_list = {
					{type = "variable", "a"},
					{type = "variable", "b", assign_to = "c"},
					is_destructuring = "table"
				},
				expression_list = {
					{type = "variable", "d"}
				},
				is_local = true
			}}, lexer:match("local {a, b => c} = d;"))
	end)

	it("can parse destructuring arrays to local assignment", function()
		assert.same({{pos = 1, type = "assignment",
				variable_list = {
					{type = "variable", "a"},
					is_destructuring = "array"
				},
				expression_list = {
					{type = "variable", "b"}
				},
				is_local = true
			}}, lexer:match("local [a] = b;"))
	end)

	it("can parse multi value assignment", function()
		assert.same({{pos = 1, type = "assignment",
				variable_list = {
					{type = "variable", "a"},
					{type = "variable", "b"}
				},
				expression_list = {
					{type = "variable", "c"},
					{type = "variable", "d"}
				}
			}}, lexer:match("a, b = c, d;"))
	end)

	it("can parse replacement assignment", function()
		assert.same({{pos = 1, type = "assignment",
				variable_list = {
					{type = "variable", "a"},
					{type = "variable", "b"}
				},
				expression_list = {
					{type = "variable", "b"},
					{type = "variable", "a"}
				}
			}}, lexer:match("a, b = b, a;"))
	end)

	it("can parse complex expressions", function()
		assert.same({{pos = 1, type = "assignment",
				variable_list = {
					{type = "variable", "a"}
				},
				expression_list = {{type = "expression",
					{type = "boolean", false},
					{type = "expression",
						{type = "variable", "b"},
						{type = "variable", "c"},
						operator = "^",
					},
					{type = "expression",
						{type = "variable", "d"},
						{type = "variable", "e"},
						operator = "/",
					},
					operator = "?:",
				}}
			}}, lexer:match("a = (?: false (^ b c) (/ d e));"))
	end)

	it("can translate mathematical constants", function()
		assert.same({{pos = 1, type = "assignment",
				variable_list = {
					{type = "variable", "a"},
					{type = "variable", "b"},
					{type = "variable", "c"}
				},
				expression_list = {
					{type = "number", 5, base = "10"},
					{type = "number", 3, base = "10", is_negative = true},
					{type = "number", 0xAF, base = "16"}
				}
			}}, lexer:match("a, b, c = 5, -3, 0xAF;"))
	end)

	it("can parse a simple function", function()
		assert.same({{pos = 1, type = "function_call", {
			{type = "variable", "func"}
		}}}, lexer:match("func();"))
	end)

	it("can parse chained functions", function()
		assert.same({{pos = 1, type = "function_call",
			{{type = "variable", "func"}},
			{{type = "variable", "two"}},
			{has_self = "three"},
			{{type = "variable", "four"},has_self = "five"}
		}}, lexer:match("func().two():three().four:five();"))
	end)

	it("can parse arguments passed to a function", function()
		assert.same({{pos = 1, type = "function_call", {
				{type = "variable", "func"},
				expression_list = {
					{type = "variable", "test"},
					{type = "variable", "test_two"}
				}}
			}}, lexer:match("func(test, test_two);"))
	end)

	it("can parse a complex function call", function()
		assert.same({{pos = 1, type = "function_call", {
				{type = "variable", "table", "instance"}, -- tables parse -this- way
				expression_list = {
					{type = "variable", "argument"}
				},
				has_self = "method"
			}}}, lexer:match("table.instance:method(argument);"))
	end)

	it("can parse a non-generated table", function()
		assert.same({{pos = 1, type = "assignment",
				variable_list = {{type = "variable", "a"}},
				expression_list = {
					{type = "table",
						{type = "number", 1, base = "10"},
						{{type = "number", 2, base = "10"}, name = "b"},
						{{type = "number", 3, base = "10"},
							index = {type = "variable", "c"}}
					}
				}
			}}, lexer:match("a = {1, b = 2, [c] = 3};"))
	end)

	it("can parse a generated table", function()
		assert.same({{pos = 1, type = "assignment",
			variable_list = {{type = "variable", "a"}},
			expression_list = {{type = "table",
				{type = "generator",
					{type = "variable", "x"}, -- left hand side
					{type = "variable", "y"}
				}
			}}
		}}, lexer:match("a = {x in y};"))
	end)

	it("can parse a complex generated table", function()
		assert.same({{pos = 1, type = "assignment",
				variable_list = {{type = "variable", "a"}},
				expression_list = {{type = "table",
					{type = "generator",
						variable_list = {
							{type = "variable", "x"},
							{type = "variable", "z"}
						},
						{type = "expression",
							{type = "variable", "x"},
							{type = "sqstring", ": "},
							{type = "variable", "z"},
							operator = ".."
						},
						{type = "function_call", {
							{type = "variable", "y"},
							expression_list = {
								{type = "variable", "a"},
								{type = "variable", "b"}
							}
						}}
					}
				}}
			}}, lexer:match("a = {(.. x ': ' z) for x, z in y(a, b)};"))
	end)

	it("can parse tables with variable non-numeric indexes", function()
		assert.same({{pos = 1, type = "assignment",
			variable_list = {{type = "variable", "a"}},
			expression_list = {{type = "table",
				{type = "generator",
					{{type = "variable", "a"}, index = {type = "variable", "x"}},
					{type = "variable", "y"}
				}
			}}
		}}, lexer:match("a = {[x] = a in y};"))
	end)

	it("can parse while loops", function()
		assert.same({{pos = 1, type = "while_loop",
				{pos = 12, type = "function_call", {
					{type = "variable", "print"},
					expression_list = {{type = "sqstring", "hi!"}}
				}},
				condition = {type = "boolean", true}
			}}, lexer:match("while true print('hi!');"))
	end)

	it("can parse numeric for loops", function()
		assert.same({{pos = 1, type = "numeric_for_loop",
				{pos = 19, type = "function_call", {
					{type = "variable", "print"},
					expression_list = {{type = "variable", "i"}}
				}},
				start = {type = "number", 1, base = "10"},
				stop = {type = "number", 100, base = "10"},
				step = {type = "number", 5, base = "10"},
				incremented_variable = "i"
			}}, lexer:match("for (i=1, 100, 5) print(i);"))
	end)

	it("can parse iterative for loops", function()
		assert.same({{pos = 1, type = "iterative_for_loop",
				{type = "variable", "x"},
				{pos = 14, type = "function_call", {
					{type = "variable", "print"},
					expression_list = {{type = "variable", "i"}}
				}},
				variable_list = {{type = "variable", "i"}}
			}}, lexer:match("for (i in x) print(i);"))
	end)

	it("can parse function definitions", function()
		assert.same({{pos = 1, type = "function_definition",
				{type = "variable", "test"},
				{
					{name = "a"},
					{
						name = "b",
						default = {type = "sqstring", "c"}
					},
					{name = "..."} -- vararg
				},
				{pos = 23, type = "return",
					expression_list = {
						{type = "variable", "a"},
						{type = "variable", "b"}
					}
				}
			}}, lexer:match("test(a, b='c', ...)-> return a, b;"))
	end)

	it("can parse lambda definitions", function()
		assert.same({{pos = 1, type = "assignment",
			variable_list = {{type = "variable", "a"}},
			expression_list = {{type = "lambda",
				expression_list = {{type = "sqstring", "hi"}}
			}}
		}}, lexer:match("a = \\-> 'hi';"))
	end)

	it("can parse method definitions", function()
		assert.same({{pos = 1, type = "function_definition",
				{type = "variable", "test"},
				{{name = "a"},
					{name = "b",
						default = {type = "sqstring", "c"}}},
				{pos = 18, type = "return",
					expression_list = {
						{type = "variable", "a"},
						{type = "variable", "b"}}},
				is_self = true
			}}, lexer:match("test(a, b='c')=> return a, b;"))
	end)

	it("can parse lambda method definitions", function()
		assert.same({{pos = 1, type = "assignment",
			variable_list = {{type = "variable", "a"}},
			expression_list = {{type = "lambda",
				expression_list = {{type = "sqstring", "hi"}},
				is_self = true
			}}
		}}, lexer:match("a = \\=> 'hi';"))
	end)

	it("can parse async function definitions", function()
		assert.same({{pos = 1, type = "function_definition",
				{type = "variable", "test"},
				{{name = "a"},
					{name = "b",
						default = {type = "sqstring", "c"}}},
				{pos = 24, type = "return",
					expression_list = {
						{type = "variable", "a"},
						{type = "variable", "b"}
					}
				},
				is_async = true
			}}, lexer:match("async test(a, b='c')-> return a, b;"))
	end)

	it("can parse async method definitions", function()
		assert.same({{pos = 1, type = "function_definition",
				{type = "variable", "test"},
				{{name = "a"},
					{name = "b",
						default = {type = "sqstring", "c"}}},
				{pos = 24, type = "return",
					expression_list = {
						{type = "variable", "a"},
						{type = "variable", "b"}}},
				is_self = true,
				is_async = true
			}}, lexer:match("async test(a, b='c')=> return a, b;"))
	end)

	it("can parse simple if statements", function()
		assert.same({{pos = 1, type = "if",
			condition = {type = "variable", "x"},
			{pos = 6, type = "function_call", {
				{type = "variable", "print"},
				expression_list = {{type = "sqstring", "test"}}
			}},
			["elseif"] = {}
		}}, lexer:match("if x print('test');"))
	end)

	it("can parse complex if statements", function()
		assert.same({{pos = 1, type = "if",
				condition = {type = "variable", "x"},
				{pos = 6, type = "function_call", {
					{type = "variable", "print"},
					expression_list = {{type = "sqstring", "test"}}
				}},
				['else'] = {pos = 26, type = "function_call", {
					{type = "variable", "print"},
					expression_list = {{type = "variable", "x"}}
				}},
				["elseif"] = {}
			}}, lexer:match("if x print('test'); else print(x);"))
	end)

	it("can parse basic classes", function()
		assert.same({{pos = 1, type = "class", {},
			name = {type = "variable", "x"}}}, lexer:match("class x {}"))
	end)

	it("can parse local classes", function()
		assert.same({{pos = 1, type = "class", {},
			is_local = true,
			name = {type = "variable", "x"}}}, lexer:match("local class x {}"))
	end)

	it("can parse classes with methods", function()
		assert.same({{pos = 1, type = "class",
			{{type = "function_definition",
					{type = "variable", "y"},
					expression_list = {{type = "variable", "z"}}}},
			name = {type = "variable", "x"},
		}}, lexer:match("class x { y()-> z }"))
	end)

	it("can parse classes with statically named values", function()
		assert.same({{pos = 1, type = "class",
			{
				{type = "class_field", {type = "variable", "z"}, name = "y"}
			},
			name = {type = "variable", "x"},
		}}, lexer:match("class x { y = z; }"))
	end)

	it("can parse classes with dynamically named values", function()
		assert.same({{pos = 1, type = "class",
			{
				{type = "class_field",
				{type = "variable", "z"},
				index = {type = "variable", "y"}}
			},
			name = {type = "variable", "x"},
		}}, lexer:match("class x { [y] = z; }"))
	end)

	it("can parse extended classes", function()
		assert.same({{pos = 1, type = "class",
			{},
			name = {type = "variable", "x"},
			extends = {type = "variable", "y"}
		}}, lexer:match("class x extends y {}"))
	end)

	it("can parse very complex classes", function()
		assert.same({{pos = 1, {},
			implements = {type = "variable", "z"},
			extends = {type = "variable", "y"},
			name = {type = "variable", "x"},
			type = "class"
		}}, lexer:match("class x extends y implements z {}"))
	end)

	it("can parse `using` statements", function()
		assert.same({{pos = 1,
			type = "using", "re"}}, lexer:match("using re;"))
	end)

	it("can parse multi-directive `using` statements", function()
		assert.same({{pos = 1, type = "using",
			"ternary", "class"}}, lexer:match("using {ternary, class};"))
	end)

	it("can parse LPeg regex literals", function()
		assert.same({{pos = 1, type="return",
			expression_list = {{type="re", "test"}}}},
			lexer:match("return /test/;"))
	end)
end)
