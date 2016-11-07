describe("lexer", function()
	local lexer = require("fusion.core.lexer")
	it("can do basic assignment", function()
		assert.same(lexer:match("a = b;"), {
			{"assignment", {
				variable_list = {
					{"variable", "a"}
				},
				expression_list = {
					{"variable", "b"}
				}
			}}
		})
	end)
	it("can do local assignment", function()
		assert.same(lexer:match("local a = b;"), {
			{"assignment", {
				variable_list = {
					{"variable", "a"}
				},
				expression_list = {
					{"variable", "b"}
				},
				is_local = true
			}}
		})
	end)
	it("can do multi value assignment", function()
		assert.same(lexer:match("a, b = c, d;"), {
			{"assignment", {
				variable_list = {
					{"variable", "a"},
					{"variable", "b"}
				},
				expression_list = {
					{"variable", "c"},
					{"variable", "d"}
				}
			}}
		})
	end)
	it("can do replacement assignment", function()
		assert.same(lexer:match("a, b = b, a;"), {
			{"assignment", {
				variable_list = {
					{"variable", "a"},
					{"variable", "b"}
				},
				expression_list = {
					{"variable", "b"},
					{"variable", "a"}
				}
			}}
		})
	end)
	it("can do complex expressions", function()
		assert.same(lexer:match("a = (+ (^ b c) (/ d e));"), {
			{"assignment", {
				variable_list = {
					{"variable", "a"}
				},
				expression_list = {{ "expression",
					{"expression",
						{"variable", "b"},
						{"variable", "c"},
						operator = "^",
					},
					{"expression",
						{"variable", "d"},
						{"variable", "e"},
						operator = "/",
					},
					operator = "+",
				}}
			}}
		})
	end)
	it("can translate mathematical constants", function()
		assert.same(lexer:match("a, b, c = 5, -3, 0xAF;"), {
			{"assignment", {
				variable_list = {
					{"variable", "a"},
					{"variable", "b"},
					{"variable", "c"}
				},
				expression_list = {
					{"number", 5, type = "base10"},
					{"number", 3, type = "base10", is_negative = true},
					{"number", 0xAF, type = "base16"}
				}
			}}
		})
	end)
	it("can parse a simple function", function()
		assert.same(lexer:match("func();"), {{"function_call",
			{"variable", "func"}
		}})
	end)
	it("can parse a generated function loop", function()
		assert.same(lexer:match("func(a for a in b);"), {{"function_call",
			{"variable", "func"},
			generator = {
				{"variable", "a"},
				{"variable", "b"},
				variable_list = {{"variable", "a"}}
			}
		}})
	end)
	it("can parse arguments passed to a function", function()
		assert.same(lexer:match("func(test, test_two);"), {{"function_call",
			{"variable", "func"},
			expression_list = {
				{"variable", "test"},
				{"variable", "test_two"}
			}
		}})
	end)
	it("can parse a complex function call", function()
		assert.same(lexer:match("table.instance:method<subclass>(argument);"), {{
			"function_call",
			{"variable", "table", "instance"}, -- tables parse -this- way
			{"variable", "method"},
			expression_list = {
				{"variable", "argument"}
			},
			has_self = true,
			index_class = "subclass"
		}})
	end)
	it("can parse a non-generated table", function()
		assert.same(lexer:match("a = {1, b = 2, [c] = 3};"), {{"assignment", {
			variable_list = {{"variable", "a"}},
			expression_list = {
				{"table",
					{"number", 1, type = "base10"},
					{{"number", 2, type = "base10"}, name = "b"},
					{{"number", 3, type = "base10"}, index = {"variable", "c"}}
				}
			}
		}}})
	end)
	it("can parse a generated table", function()
		assert.same(lexer:match("a = {x in y};"), {{"assignment", {
			variable_list = {{"variable", "a"}},
			expression_list = {{"table",
				{"generator",
					{"variable", "x"}, -- left hand side
					{"variable", "y"}
				}
			}}
		}}})
	end)
	it("can parse a complex generated table", function()
		assert.same(lexer:match("a = {(.. x ': ' z) for x, z in y(a, b)};"),
		{{"assignment", {
			variable_list = {{"variable", "a"}},
			expression_list = {{"table",
				{"generator",
					variable_list = {{"variable", "x"}, {"variable", "z"}},
					{"expression",
						{"variable", "x"},
						{"sqstring", ": "},
						{"variable", "z"},
						operator = ".."
					},
					{"function_call",
						{"variable", "y"},
						expression_list = {
							{"variable", "a"},
							{"variable", "b"}
						}
					}
				}
			}}
		}}})
	end)
	it("can parse tables with variable non-numeric indexes", function()
		assert.same(lexer:match("a = {[x] = a in y};"), {{"assignment", {
			variable_list = {{"variable", "a"}},
			expression_list = {{"table",
				{"generator",
					{{"variable", "a"}, index = {"variable", "x"}},
					{"variable", "y"}
				}
			}}
		}}})
	end)
	it("can parse while loops", function()
		assert.same(lexer:match("while true print('hi!');"), {{"while_loop",
			{"function_call",
				{"variable", "print"},
				expression_list = {{"sqstring", "hi!"}}
			},
			condition = {"boolean", true}
		}})
	end)
	it("can parse numeric for loops", function()
		assert.same(lexer:match("for (i=1, 100, 5) print(i);"),
		{{"numeric_for_loop",
			{"function_call",
				{"variable", "print"},
				expression_list = {{"variable", "i"}}
			},
			start = {"number", 1, type = "base10"},
			stop = {"number", 100, type = "base10"},
			step = {"number", 5, type="base10"},
			incremented_variable = "i"
		}})
	end)
	it("can parse iterative for loops", function()
		assert.same(lexer:match("for (i in x) print(i);"),
		{{"iterative_for_loop",
			{"variable", "x"},
			{"function_call",
				{"variable", "print"},
				expression_list = {{"variable", "i"}}
			},
			variable_list = {{"variable", "i"}}
		}})
	end)
end)