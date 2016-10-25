/* vim:set noet sts=0 sw=2 ts=2: */
#pragma once

#include <string>
#include <vector>

#define FIRST_TOKEN 256
/* 256 possible for char, plus one */

#define f_check_next(pos, test_char)	get_next(pos, input) == test_char
#define f_iswhitespace(test_char) test_char == ' ' || \
	test_char == '\t' || \
	test_char == '\n' || \
  test_char == '\v' || \
	test_char == '\f'

namespace fusion {
	struct token {
		enum token_t {
			/* keywords */
			TOK_ELSE = FIRST_TOKEN, TOK_IF, TOK_TRUE, TOK_FALSE, TOK_NIL, TOK_WHILE,
			TOK_IN, TOK_NEW, TOK_EXTENDS, TOK_FOR, TOK_ASYNC, TOK_YIELD,
			/* binary operators with more than one char*/
			TOK_BOOLAND, TOK_BOOLOR, TOK_RSHIFT, TOK_LSHIFT, TOK_EQ, TOK_NEQ, TOK_GE,
			TOK_LE, TOK_CONCAT, TOK_FLOORDIV,
			/* extra tokens */
			TOK_VARARG, TOK_NUM, TOK_STRING, TOK_NAME, TOK_END, TOK_WHITE
		} type;
		std::string self;
	};

	struct TokenizerState {
		uint32_t current_line;
		uint32_t position;
		std::vector<token> tokens;
		std::string input;
	};

	const struct TokenizerState TOKENIZER_STATE_DEFAULT = {
		1, 0, std::vector<token>(), ""
	};

	char get_next(uint32_t position, std::string input);

	std::pair<bool, std::string> try_parse_num(TokenizerState *ts);

	void tokenize(TokenizerState *ts, std::string input);
}
