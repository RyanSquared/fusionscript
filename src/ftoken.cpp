/* vim:set noet sts=0 sw=2 ts=2: */
#include <cctype>
#include <array>
#include <utility>

#include "ftoken.hpp"

using namespace std;


namespace fusion {

	using namespace std;

	array<string, 25> fusion_tokens = {
		"else", "if", "true", "false", "nil", "while", "in", "new", "extends", "for",
		/* */
		"&&", "||", ">>", "<<", "==", "!=", ">=", "<=", ".."
		/* */
		"...", "[eof]", "[int]", "[num]", "[str]", "[name]"
	};

	/* ::TODO:: */
	pair<bool, string> try_parse_num(TokenizerState *ts) {
		return pair<bool, string>(true, "");
	}
	bool is_reserved(string word) {return true;}

	void ftokenize(TokenizerState *ts, string input) {
		/* initialize the tokenizer state */
		ts->position = 0;
		ts->current_line = 1;
		ts->tokens = vector<token>();
		ts->input = input;

		/* search through string for a token */
		while (true) {
			switch (input[ts->position]) {
				case '\r': {
					/* ignore \r for Windows support */
					ts->position++;
					break;
				}
				case '\n': {
					ts->current_line++;
					ts->position++;
					break;
				}
				case ' ': case '\t': case '\v': case '\f': {
					ts->position++;
				}
				case '&': {
					/* check for && otherwise & */
					if (check_next(1, '&')) {
						/* generate token for && and incr position to skip over */
						ts->tokens.push_back({
							token::TOK_BOOLAND, /* token::type */
							"&&"                /* string self */
						});
						ts->position += 2;
					break;
					} /* end if */ /* do not process just & */
					/* the nonbreaking default will process single-char tokens */
				} /* end case */
				case '|': {
					/* same as above, check for || otherwise | */
					if (check_next(1, '|')) {
						/* generate || token and incr */
						ts->tokens.push_back({token::TOK_BOOLOR, "||"});
						ts->position += 2;
						break;
					}
				} /* end case */
				case '>': {
					/* check for >>, check for >=, or DON'T break */
					/* the char lives as itself as a token if nobreak */
					bool is_single_char = false;
					char next = input[ts->position + 1];
					switch (next) {
						case '>':
							ts->tokens.push_back({token::TOK_RSHIFT, ">>"});
							break;
						case '=':
							ts->tokens.push_back({token::TOK_GE, ">="});
							break;
						default:
							is_single_char = true;
					} /* end switch */
					if (!is_single_char) {
						ts->position += 2;
						break;
					}
				} /* end case */
				case '<': {
					/* duplicate above again, but with < */
					bool is_single_char = false;
					char next = input[ts->position + 1];
					switch(next) {
						case '<':
							ts->tokens.push_back({token::TOK_LSHIFT, "<<"});
							break;
						case '=':
							ts->tokens.push_back({token::TOK_LE, "<="});
							break;
						default:
							is_single_char = true;
					} /* end switch */
					if (!is_single_char) {
						ts->position += 2;
						break;
					}
				} /* end case */
				case '=': {
					/* check == else = */
					if (check_next(1, '=')) {
						ts->tokens.push_back({token::TOK_EQ, "=="});
						ts->position += 2;
						break;
					}
				}
				case '!': {
					/* check != else = */
					if (check_next(1, '=')) {
						ts->tokens.push_back({token::TOK_NEQ, "!="});
						ts->position += 2;
						break;
					}
				}
				case '.': {
					/* check .., then ...; if not ... then ..; then . */
					auto result = try_parse_num(ts); /* ::TODO:: try_parse_num */
					if (get<0>(result)) { /* true if number, false if not */
						/* get<1>(result) should return a std::string */
						string result_num = get<1>(result);
						ts->tokens.push_back({token::TOK_NUM, result_num});
						ts->position += result_num.length();
					} else if (check_next(1, '.')) {
						if (check_next(2, '.')) {
							/* ... */
							ts->tokens.push_back({token::TOK_VARARG, "..."});
							ts->position += 3;
							break;
						} else {
							/* .. */
							ts->tokens.push_back({token::TOK_CONCAT, ".."});
							ts->position += 3;
							break;
						}
					} /* end else if */
				} /* end case */
				case '"': { /* ::TODO:: ' */
					string buffer = "";
					ts->position++; /* increment position past the " */
					char current = '\0'; /* current in string */
					while (current != '"') { /* we can pass over '\"' during the loop */
						current = input[ts->position];
						if (current == '\r' || current == '\n') {
							/* break on new line. you can use \n like everyone else >:C */
							/* ::TODO:: implement erroring */
						} else if (current == '\\') { /* process escape code, C-style */
							buffer += "\\" + input[ts->position + 1];
							ts->position += 2;
						} else {
							buffer += current;
							ts->position++;
						}
					} /* end while */
					ts->tokens.push_back({token::TOK_STRING, buffer});
						/* hope this works TODO */
					break;
				} /* end case */
				case '0': case '1': case '2': case '3': case '4':
				case '5': case '6': case '7': case '8': case '9': {
					/* no matter what, this should return a number */
					/* we don't need to test try_parse_num[1] */
					string result_num = get<1>(try_parse_num(ts)); /* ::TODO:: */
					ts->tokens.push_back({token::TOK_NUM, result_num});
					ts->position += result_num.length();
					break;
				} /* end case */
				default: {
					/* ::TODO:: is_reserved(keyword) -> bool */
					if (isalpha(input[ts->position])) {
						string word = "";
						while (isalnum(input[ts->position])) {
							 word += input[ts->position];
							 ts->position++;
						} /* end while */
							/* fully captured word, check if reserved keyword */
						if (is_reserved(word))
							/* it is a reserved keyword */
							for (auto iter = fusion_tokens.begin();
									iter != fusion_tokens.end(); ++iter)
								/* find reserved word and push token */
								if (word == *iter) {
									/* found reserved word */
									uint16_t pos = iter - fusion_tokens.begin();
									ts->tokens.push_back({
										static_cast<token::token_t>(pos + FIRST_TOKEN),
										word
									});
								} /* end if */
						else ts->tokens.push_back({token::TOK_NAME, word});
							/* used as an identifier */
					} else {
						token::token_t char_to_token =
							static_cast<token::token_t>(input[ts->position]);
						//ts->tokens.push_back({char_to_token, input[ts->position]});
						ts->position++;
					} /* end else */
				} /* end default */

			} /* end switch */
		} /* end while */
	} /* end function */

} /* end namespace */
#ifdef HOMEWORK_DEBUG
int main() { return 0; }
#endif
