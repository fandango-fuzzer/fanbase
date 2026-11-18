# Same models as uvl, with the lexical detail that the reference grammar
# allows, and that each of its parsers handles in its own indentation-tracking
# lexer. All of it is in uvl-parser's own test models:
#   - CRLF and lone CR line ends, mixed within a file;
#   - comments on lines of their own at any indentation, and block comments,
#     spanning lines and with tabs in them, at the end of a line or on lines
#     of their own (test_models/syntax/comments_and_blanks);
#   - attribute blocks and constraint lists broken across lines: a line end
#     inside brackets is not a line end of the tree;
#   - blank lines, with or without spaces in them, anywhere; comments and blank
#     lines before the first section, when that is not a namespace (the grammar
#     has no line end before one).
# ASCII only, like uvl.

include("uvl/uvl.fan")

<start> ::= (
      <namespace_section> <include_section>? <imports_section>? <features_section> <constraints_section>? <trailing>?
    | <leading>? <include_section>? <imports_section>? <features_section> <constraints_section>? <trailing>?
    )
<leading> ::= (<newline> | <note>){1,3}
<trailing> ::= <newline>{1,2}


# --- line ends and comments

<newline> ::= "\n" | "\n" | "\r\n" | "\r"
<eol> ::= <trailing_space>? (<line_comment> | <inline_block_comment>)? <newline> <blank_line>?
<blank_line> ::= r"[ \t]{0,4}" <newline>
<line_comment> ::= r" {1,2}" "//" <comment_text>
<inline_block_comment> ::= r" {1,2}" "/*" <block_text> "*/"

# a comment line, indented any way, after the indentation of the line it is in front of
<note> ::= r"[ \t]{0,6}" ("//" <comment_text> | "/*" <block_text> "*/") <newline>

<comment_text> ::= r"[a-zA-Z0-9 \t,.:!?()-]{0,24}"
<block_text> ::= r"([a-zA-Z0-9 \t,.:!?()-]|\n|\*[a-zA-Z ])*"


# --- brackets broken across lines

<wrap> ::= " " | <newline> r"[ \t]{0,12}"

<attributes> ::= "{" <wrap>? (<attribute> ("," <wrap> <attribute>){0,3})? <wrap>? "}"
<constraint_list> ::= "[" <wrap>? (<constraint> ("," <wrap> <constraint>){0,2})? <wrap>? "]"
