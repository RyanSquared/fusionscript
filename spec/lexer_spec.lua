describe("lexer", function()
	local lexer = require("fusion.core.lexer")
	it("can send appropriate errors", function()
		local err_syntax = assert.errors(function() lexer:match("fail") end)
		assert.same(err_syntax.quick, "syntax")
		assert.same(err_syntax.context, "fail")
		assert.is_not.same(tostring(err_syntax):sub(1, 5), "table")
		local err_sc = assert.errors(function() lexer:match("fail()") end)
		assert.same(err_sc.quick, "semicolon")
		assert.same(err_sc.context, "fail()")
		assert.is_not.same(tostring(err_sc):sub(1, 5), "table")
		local err_syntax_2 = assert.errors(function()
				lexer:match("test();\nasdf") end)
		assert.same(err_syntax_2.quick, "syntax")
		assert.same(err_syntax_2.context, "asdf")
		assert.is_not.same(tostring(err_syntax_2):sub(1, 5), "table")
		local err_sc_2 = assert.errors(function()
				lexer:match("test();\nreturn") end)
		assert.same(err_sc_2.quick, "semicolon")
		assert.same(err_sc_2.context:sub(-6), "return")
		assert.is_not.same(tostring(err_sc_2):sub(1, 5), "table")
	end)
	it("can parse break statements", function()
		assert.same(lexer:match("break;"), {{type = "break"}})
	end)
	it("can parse simple yield statements", function()
		assert.same(lexer:match("yield;"), {{type = "yield"}})
	end)
	it("can parse complex yield statements", function()
		assert.same(lexer:match("yield a, b;"), {{type = "yield",
			expression_list = {
				{type = "variable", "a"},
				{type = "variable", "b"}
			}
		}})
	end)
	it("can parse simple return statements", function()
		assert.same(lexer:match("return;"), {{type = "return"}})
	end)
	it("can parse complex return statements", function()
		assert.same(lexer:match("return a, b;"), {{type = "return",
			expression_list = {
				{type = "variable", "a"},
				{type = "variable", "b"}
			}
		}})
	end)
	it("can parse basic assignment", function()
		assert.same(lexer:match("a = b;"), {
			{type = "assignment",
				variable_list = {
					{type = "variable", "a"}
				},
				expression_list = {
					{type = "variable", "b"}
				}
			}
		})
	end)
	it("can parse local assignment", function()
		assert.same(lexer:match("local a = b;"), {
			{type = "assignment",
				variable_list = {
					{type = "variable", "a"}
				},
				expression_list = {
					{type = "variable", "b"}
				},
				is_local = true
			}
		})
	end)
	it("can parse self indexing", function()
		assert.same(lexer:match("local a = @b;"), {
			{type = "assignment",
				variable_list = {
					{type = "variable", "a"}
				},
				expression_list = {
					{type = "variable", "self", "b"}
				},
				is_local = true
			}
		})
	end)
	it("can parse complex self indexing", function()
		assert.same(lexer:match("local a = @[b];"), {
			{type = "assignment",
				variable_list = {
					{type = "variable", "a"}
				},
				expression_list = {
					{type = "variable", "self", {type = "variable", "b"}}
				},
				is_local = true
			}
		})
	end)
	it("can parse assigning to self", function()
		assert.same(lexer:match("@a = b;"), {
			{type = "assignment",
				variable_list = {
					{type = "variable", "self", "a"}
				},
				expression_list = {
					{type = "variable", "b"}
				}
			}
		})
	end)
	it("can parse destructuring tables to local assignment", function()
		assert.same(lexer:match("local {a} = b;"), {
			{type = "assignment",
				variable_list = {
					{type = "variable", "a"},
					is_destructuring = "table"
				},
				expression_list = {
					{type = "variable", "b"}
				},
				is_local = true
			}
		})
	end)
	it("can parse destructuring arrays to local assignment", function()
		assert.same(lexer:match("local [a] = b;"), {
			{type = "assignment",
				variable_list = {
					{type = "variable", "a"},
					is_destructuring = "array"
				},
				expression_list = {
					{type = "variable", "b"}
				},
				is_local = true
			}
		})
	end)
	it("can parse multi value assignment", function()
		assert.same(lexer:match("a, b = c, d;"), {
			{type = "assignment",
				variable_list = {
					{type = "variable", "a"},
					{type = "variable", "b"}
				},
				expression_list = {
					{type = "variable", "c"},
					{type = "variable", "d"}
				}
			}
		})
	end)
	it("can parse replacement assignment", function()
		assert.same(lexer:match("a, b = b, a;"), {
			{type = "assignment",
				variable_list = {
					{type = "variable", "a"},
					{type = "variable", "b"}
				},
				expression_list = {
					{type = "variable", "b"},
					{type = "variable", "a"}
				}
			}
		})
	end)
	it("can parse complex expressions", function()
		assert.same(lexer:match("a = (?: false (^ b c) (/ d e));"), {
			{type = "assignment",
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
			}
		})
	end)
	it("can translate mathematical constants", function()
		assert.same(lexer:match("a, b, c = 5, -3, 0xAF;"), {
			{type = "assignment",
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
			}
		})
	end)
	it("can parse a simple function", function()
		assert.same(lexer:match("func();"), {{type = "function_call",
			{type = "variable", "func"}
		}})
	end)
	it("can parse a simple generated function loop", function()
		assert.same(lexer:match("func(a in b);"), {{type = "function_call",
			{type = "variable", "func"},
			generator = {
				{type = "variable", "b"},
				variable_list = {{type = "variable", "a"}}
			}
		}})
	end)
	it("can parse a complex generated function loop", function()
		assert.same(lexer:match("func(a for a in b);"), {{type = "function_call",
			{type = "variable", "func"},
			generator = {
				{type = "variable", "b"},
				expression_list = {{type = "variable", "a"}},
				variable_list = {{type = "variable", "a"}}
			}
		}})
	end)
	it("can parse arguments passed to a function", function()
		assert.same(lexer:match("func(test, test_two);"), {
			{type = "function_call",
				{type = "variable", "func"},
				expression_list = {
					{type = "variable", "test"},
					{type = "variable", "test_two"}
				}
			}
		})
	end)
	it("can parse a complex function call", function()
		assert.same(lexer:match("table.instance:method<subclass>(argument);"), {
			{type = "function_call",
				{type = "variable", "table", "instance"}, -- tables parse -this- way
				expression_list = {
					{type = "variable", "argument"}
				},
				has_self = "method",
				index_class = "subclass"
			}
		})
	end)
	it("can parse a non-generated table", function()
		assert.same(lexer:match("a = {1, b = 2, [c] = 3};"), {
			{type = "assignment",
				variable_list = {{type = "variable", "a"}},
				expression_list = {
					{type = "table",
						{type = "number", 1, base = "10"},
						{{type = "number", 2, base = "10"}, name = "b"},
						{{type = "number", 3, base = "10"},
							index = {type = "variable", "c"}}
					}
				}
			}
		})
	end)
	it("can parse a generated table", function()
		assert.same(lexer:match("a = {x in y};"), {{type = "assignment",
			variable_list = {{type = "variable", "a"}},
			expression_list = {{type = "table",
				{type = "generator",
					{type = "variable", "x"}, -- left hand side
					{type = "variable", "y"}
				}
			}}
		}})
	end)
	it("can parse a complex generated table", function()
		assert.same(lexer:match("a = {(.. x ': ' z) for x, z in y(a, b)};"), {
			{type = "assignment",
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
						{type = "function_call",
							{type = "variable", "y"},
							expression_list = {
								{type = "variable", "a"},
								{type = "variable", "b"}
							}
						}
					}
				}}
			}
		})
	end)
	it("can parse tables with variable non-numeric indexes", function()
		assert.same(lexer:match("a = {[x] = a in y};"), {{type = "assignment",
			variable_list = {{type = "variable", "a"}},
			expression_list = {{type = "table",
				{type = "generator",
					{{type = "variable", "a"}, index = {type = "variable", "x"}},
					{type = "variable", "y"}
				}
			}}
		}})
	end)
	it("can parse while loops", function()
		assert.same(lexer:match("while true print('hi!');"), {
			{type = "while_loop",
				{type = "function_call",
					{type = "variable", "print"},
					expression_list = {{type = "sqstring", "hi!"}}
				},
				condition = {type = "boolean", true}
			}
		})
	end)
	it("can parse numeric for loops", function()
		assert.same(lexer:match("for (i=1, 100, 5) print(i);"), {
			{type = "numeric_for_loop",
				{type = "function_call",
					{type = "variable", "print"},
					expression_list = {{type = "variable", "i"}}
				},
				start = {type = "number", 1, base = "10"},
				stop = {type = "number", 100, base = "10"},
				step = {type = "number", 5, base = "10"},
				incremented_variable = "i"
			}
		})
	end)
	it("can parse iterative for loops", function()
		assert.same(lexer:match("for (i in x) print(i);"), {
			{type = "iterative_for_loop",
				{type = "variable", "x"},
				{type = "function_call",
					{type = "variable", "print"},
					expression_list = {{type = "variable", "i"}}
				},
				variable_list = {{type = "variable", "i"}}
			}
		})
	end)
	it("can parse function definitions", function()
		assert.same(lexer:match("test(a, b='c', ...)-> return a, b;"), {
			{type = "function_definition",
				{type = "variable", "test"},
				{
					{name = "a"},
					{
						name = "b",
						default = {type = "sqstring", "c"}
					},
					{name = "..."} -- vararg
				},
				{type = "return",
					expression_list = {
						{type = "variable", "a"},
						{type = "variable", "b"}
					}
				}
			}
		})
	end)
	it("can parse lambda definitions", function()
		assert.same(lexer:match("a = \\-> 'hi';"), {{type = "assignment",
			variable_list = {{type = "variable", "a"}},
			expression_list = {{type = "lambda",
				expression_list = {{type = "sqstring", "hi"}}
			}}
		}})
	end)
	it("can parse method definitions", function()
		assert.same(lexer:match("test(a, b='c')=> return a, b;"), {
			{type = "function_definition",
				{type = "variable", "test"},
				{
					{name = "a"},
					{
						name = "b",
						default = {type = "sqstring", "c"}
					}
				},
				{type = "return",
					expression_list = {
						{type = "variable", "a"},
						{type = "variable", "b"}
					}
				},
				is_self = true
			}
		})
	end)
	it("can parse lambda method definitions", function()
		assert.same(lexer:match("a = \\=> 'hi';"), {{type = "assignment",
			variable_list = {{type = "variable", "a"}},
			expression_list = {{type = "lambda",
				expression_list = {{type = "sqstring", "hi"}},
				is_self = true
			}}
		}})
	end)
	it("can parse async function definitions", function()
		assert.same(lexer:match("async test(a, b='c')-> return a, b;"), {
			{type = "function_definition",
				{type = "variable", "test"},
				{
					{name = "a"},
					{
						name = "b",
						default = {type = "sqstring", "c"}
					}
				},
				{type = "return",
					expression_list = {
						{type = "variable", "a"},
						{type = "variable", "b"}
					}
				},
				is_async = true
			}
		})
	end)
	it("can parse async method definitions", function()
		assert.same(lexer:match("async test(a, b='c')=> return a, b;"), {
			{type = "function_definition",
				{type = "variable", "test"},
				{
					{name = "a"},
					{
						name = "b",
						default = {type = "sqstring", "c"}
					}
				},
				{type = "return",
					expression_list = {
						{type = "variable", "a"},
						{type = "variable", "b"}
					}
				},
				is_self = true,
				is_async = true
			}
		})
	end)
	it("can parse simple if statements", function()
		assert.same(lexer:match("if x print('test');"), {{type = "if",
			condition = {type = "variable", "x"},
			{type = "function_call",
				{type = "variable", "print"},
				expression_list = {{type = "sqstring", "test"}}
			},
			["elseif"] = {}
		}})
	end)
	it("can parse complex if statements", function()
		assert.same(lexer:match("if x print('test'); else print(x);"), {
			{type = "if",
				condition = {type = "variable", "x"},
				{type = "function_call",
					{type = "variable", "print"},
					expression_list = {{type = "sqstring", "test"}}
				},
				['else'] = {type = "function_call",
					{type = "variable", "print"},
					expression_list = {{type = "variable", "x"}}
				},
				["elseif"] = {}
			}
		})
	end)
	it("can parse basic classes", function()
		assert.same(lexer:match("class x {}"), {{type = "class", {},
			name = {type = "variable", "x"}}})
	end)
	it("can parse local classes", function()
		assert.same(lexer:match("local class x {}"), {{type = "class", {},
			is_local = true,
			name = {type = "variable", "x"}}})
	end)
	it("can parse classes with methods", function()
		assert.same(lexer:match("class x { y()-> z }"), {{type = "class",
			{
				{type = "function_definition",
					{type = "variable", "y"},
					expression_list = {{type = "variable", "z"}}
				}
			},
			name = {type = "variable", "x"},
		}})
	end)
	it("can parse classes with dynamically named values", function()
		assert.same(lexer:match("class x { y = z; }"), {{type = "class",
			{
				{type = "class_field", {type = "variable", "z"}, name = "y"}
			},
			name = {type = "variable", "x"},
		}})
	end)
	it("can parse classes with dynamically named values", function()
		assert.same(lexer:match("class x { [y] = z; }"), {{type = "class",
			{
				{type = "class_field",
				{type = "variable", "z"},
				name = {type = "variable", "y"}}
			},
			name = {type = "variable", "x"},
		}})
	end)
	it("can parse extended classes", function()
		assert.same(lexer:match("class x extends y {}"), {{type = "class",
			{},
			name = {type = "variable", "x"},
			extends = {type = "variable", "y"}
		}})
	end)
	it("can parse very complex classes", function()
		assert.same(lexer:match("class x extends y implements z {}"), {{
			{},
			implements = {type = "variable", "z"},
			extends = {type = "variable", "y"},
			name = {type = "variable", "x"},
			type = "class"
		}})
	end)
	it("can parse negative ranges", function()
		assert.same(lexer:match("a = 10::1::2;"), {{type = "assignment",
			variable_list = {{type = "variable", "a"}},
			expression_list = {{type = "range",
				start = {type = "number", base = "10", 10},
				stop = {type = "number", base = "10", 1},
				step = {type = "number", base = "10", 2}
			}}
		}})
	end)
	it("can parse complex ranges", function()
		assert.same(lexer:match("a = 1::10::2;"), {{type = "assignment",
			variable_list = {{type = "variable", "a"}},
			expression_list = {{type = "range",
				start = {type = "number", base = "10", 1},
				stop = {type = "number", base = "10", 10},
				step = {type = "number", base = "10", 2}
			}}
		}})
	end)
	it("can parse basic ranges", function()
		assert.same(lexer:match("a = 1::5;"), {{type = "assignment",
			variable_list = {{type = "variable", "a"}},
			expression_list = {{type = "range",
				start = {type = "number", base = "10", 1},
				stop = {type = "number", base = "10", 5}
			}}
		}})
	end)
	it("can parse `using` statements", function()
		assert.same(lexer:match("using fnl;"), {{type = "using", "fnl"}})
	end)
	it("can parse multi-directive `using` statements", function()
		assert.same(lexer:match("using {fnl, itr};"), {{type = "using",
			"fnl", "itr"}})
	end)
	it("can parse LPeg regex literals", function()
		assert.same(lexer:match("return /test/;"), {{type="return",
			expression_list = {{type="re", "test"}}}})
	end)
end)
