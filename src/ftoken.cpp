/* vim:set noet sts=0 sw=2 ts=2: */
#include <string>
#include <cctype>
#include <array>
#include <utility>

#include <iostream>

#include "ftoken.hpp"

namespace fusion {
	std::array<std::string, 29> tokens = {
		"else", "if", "true", "false", "nil", "while", "in", "new", "extends",
		"for", "async", "yield"
		/* */
		"&&", "||", ">>", "<<", "==", "!=", ">=", "<=", "..", "_/",
		/* */
		"...", "[int]", "[num]", "[str]", "[name]", "[eof]", "[white]"
	};

	std::pair<bool, std::string> try_parse_num(TokenizerState *ts) {
		std::string input = ts->input;
		char first = input.at(ts->position);
		if (first == '0' && (f_check_next(1, 'x') || f_check_next(1, 'X'))) {
			std::string hexable = "0123456789ABCDEF";
			std::string scanned = "";
			uint32_t pos = ts->position + 2;
			while (input.find_first_of(hexable, pos) == pos)
				scanned += input.at(++pos);
			if (scanned.length() == 0)
				return std::pair<bool, std::string>(false, "");
			char exponent = input.at(pos);
			if (exponent == 'p' || exponent == 'P') {
				scanned += exponent;
				if (input.at(pos + 1) == '-' || input.at(pos + 1) == '+')
					scanned += input.at(++pos);
				while (input.find_first_of("0123456789", pos) == pos)
					scanned += input.at(++pos);
			}
			ts->position = pos;
			return std::pair<bool, std::string>(true, scanned);
		} else if (input.find_first_of("0123456789.", ts->position)) {
			// period included for decimals
			std::string scanned = "";
			uint32_t pos = ts->position;
			while (input.find_first_of("0123456789", pos) == pos)
				scanned += input.at(++pos);
			if (input.at(pos) == '.' && (input.find("0123456789", pos) == pos + 1)) {
				pos++;
				while (input.find_first_of("0123456789", pos) == pos)
					scanned += input.at(++pos);
			}
			if (scanned != ".") { // it can potentially match just a period so don't do that
				ts->position = pos;
				return std::pair<bool, std::string>(true, scanned);
			}
		}
		return std::pair<bool, std::string>(false, "");
	}

	void tokenize(TokenizerState *ts, std::string input) {
		/* initialize the tokenizer state */
		/* search through string for a token */
		while (true) {
			try {
				switch (input.at(ts->position)) {
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
						std::string whitespace_token = "";
						while (f_iswhitespace(input.at(ts->position))) {
							whitespace_token += input.at(ts->position);
							ts->position++;
						}
						ts->tokens.push_back({token::TOK_WHITE, whitespace_token});
						break;
					}
					case '&': {
						/* check for && otherwise & */
						if (f_check_next(1, '&')) {
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
						if (f_check_next(1, '|')) {
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
						switch (input.at(ts->position + 1)) {
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
						switch(input.at(ts->position + 1)) {
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
						if (f_check_next(1, '=')) {
							ts->tokens.push_back({token::TOK_EQ, "=="});
							ts->position += 2;
							break;
						}
					}
					case '!': {
						/* check != else = */
						if (f_check_next(1, '=')) {
							ts->tokens.push_back({token::TOK_NEQ, "!="});
							ts->position += 2;
							break;
						}
					}
					case '.': {
						/* check .., then ...; if not ... then ..; then . */
						auto result = try_parse_num(ts);
						if (std::get<0>(result)) { /* true if number, false if not */
							/* get<1>(result) should return a std::string */
							std::string result_num = std::get<1>(result);
							ts->tokens.push_back({token::TOK_NUM, result_num});
							ts->position += result_num.length();
						} else if (f_check_next(1, '.')) {
							if (f_check_next(2, '.')) {
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
					case '_': { /* floor division */
						if (f_check_next(1, '/')) {
							ts->tokens.push_back({token::TOK_FLOORDIV, "_/"});
							ts->position += 2;
							break;
						}
					}
					case '"': { 
						std::string buffer = "\"";
						ts->position++; /* increment position past the " */
						char current = '\0'; /* current in string */
						while (current != '"') { /* we can pass over '\"' during the loop */
							current = input.at(ts->position);
							if (current == '\\') { /* process escape code, C-style */
								buffer += "\\" + input.at(ts->position + 2);
								ts->position += 2;
							} else if (current == '"') {
								buffer += '"';
								ts->position++;
								break;
							} else {
								buffer += current;
								ts->position++;
							}
						} /* end while */
						ts->tokens.push_back({token::TOK_STRING, buffer});
						break;
					} /* end case */
					case '\'': {
						std::string buffer = "'";
						ts->position++; /* incr past ' */
						char current = '\0';
						while (current != '\'') {
							buffer += input.at(ts->position++);
						} /* end while */
						ts->tokens.push_back({token::TOK_STRING, buffer});
						break;
					}
					case '0': case '1': case '2': case '3': case '4':
					case '5': case '6': case '7': case '8': case '9': {
						/* no matter what, this should return a number */
						/* we don't need to test try_parse_num[1] */
						std::string result_num = std::get<1>(try_parse_num(ts));
						ts->tokens.push_back({token::TOK_NUM, result_num});
						ts->position += result_num.length();
						break;
					} /* end case */
					default: {
						char current_char = input.at(ts->position);
						if (isalpha(current_char) || current_char == '_') {
							std::string word = "";
							while (isalnum(current_char) || current_char == '_') {
								word += current_char;
								current_char = input.at(++ts->position);
							} /* end while */
								/* fully captured word, check if reserved keyword */
							bool is_reserved = false;
							for (auto iter = tokens.begin();
									iter != tokens.end(); ++iter) {
								/* find reserved word and push token */
								if (word == *iter) {
									/* found reserved word */
									uint16_t pos = iter - tokens.begin();
									ts->tokens.push_back({
										static_cast<token::token_t>(pos + FIRST_TOKEN),
										word
									});
									is_reserved = true;
								} /* end if */
							} /* end for */
							if (!is_reserved) ts->tokens.push_back({token::TOK_NAME, word});
								/* used as an identifier */
						} else {
							ts->tokens.push_back({
								static_cast<token::token_t>(input.at(ts->position)),
								std::string(1, input.at(ts->position))
							});
							ts->position++;
						} /* end else */
					} /* end default */
				} /* end switch */
			} catch (std::out_of_range const &ignored_exception) {
				ts->tokens.push_back({token::TOK_END, ""});
				return;
			} /* end try */ /* end of input, return final token */
		} /* end while */
	} /* end function */
} /* end namespace */

int main() {
	fusion::TokenizerState ts = fusion::TOKENIZER_STATE_DEFAULT;
	fusion::tokenize(&ts, "print(    \"hi\" )");
	for (auto token = ts.tokens.begin(); token != ts.tokens.end(); token++) {
		if (token->type > 256)
			std::cout << fusion::tokens[token->type - 256] << " ";
		else
			std::cout << token->type << " ";
		std::cout << token->self << std::endl;
	}
	return 0;
}
