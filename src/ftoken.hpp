/* vim:set noet sts=0 sw=2 ts=2: */
#include <string>
#include <vector>

#define FIRST_TOKEN 257
/* 256 possible for char, plus one */
#define check_next(pos, test_char)	input.at(pos) == test_char

namespace fusion {

	struct token {
		enum token_t {
			/* keywords */
			TOK_ELSE = FIRST_TOKEN, TOK_IF, TOK_TRUE, TOK_FALSE, TOK_NIL, TOK_WHILE,
			TOK_IN, TOK_NEW, TOK_EXTENDS, TOK_FOR,
			/* binary operators with more than one char*/
			TOK_BOOLAND, TOK_BOOLOR, TOK_RSHIFT, TOK_LSHIFT, TOK_EQ, TOK_NEQ, TOK_GE,
			TOK_LE, TOK_CONCAT, TOK_FLOORDIV,
			/* extra tokens */
			TOK_VARARG, TOK_INT, TOK_NUM, TOK_STRING, TOK_NAME, TOK_END
		} type;
		std::string self;
	};

	struct TokenizerState {
		int current_line;
		int position;
		std::vector<token> tokens;
		std::string input;
	};

	const struct TokenizerState TOKENIZER_STATE_DEFAULT = {
		1, 0, std::vector<token>(), ""
	};
}
