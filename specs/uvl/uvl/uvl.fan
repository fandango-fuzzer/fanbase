# UVL, the Universal Variability Language: feature models as text.
# Reference grammar: https://github.com/Universal-Variability-Language/uvl-parser (uvl/*.g4)
#
# A model has up to five sections, in this order: a namespace, an include
# block naming the language levels it uses, imports of other models, the
# feature tree, and cross-tree constraints. The tree is indentation-sensitive
# (as in Python): a feature's groups are one level deeper than the feature,
# and a group's features one level deeper than the group.
#
# Fandango has no INDENT/DEDENT, so the tree is written out by depth: a root
# feature and four levels of groups below it (features down to depth 9).
# Each depth is indented by four spaces more (<in1> ... <in9>); a variant that
# redefines them indents with something else, consistently across the file.
#
# What this spec leaves out, to stay with the layout every parser of the
# reference grammar reads (uvl-lexical has the lexical detail):
#   - a vector holding a single integer, such as [1], which the lexer reads as
#     a CARDINALITY token;
#   - a minus without a space after it, as in a-1 (lexed as a, -1);
#   - comment lines indented differently from the line after them, block
#     comments, tabs, CRLF line ends, characters outside ASCII.

<start> ::= <namespace_section>? <include_section>? <imports_section>? <features_section> <constraints_section>?


# --- layout

<in1> ::= "    "
<in2> ::= "        "
<in3> ::= "            "
<in4> ::= "                "
<in5> ::= "                    "
<in6> ::= "                        "
<in7> ::= "                            "
<in8> ::= "                                "
<in9> ::= "                                    "

# the end of a line: a comment before it now and then, and blank lines after it
<eol> ::= <trailing_space>? <line_comment>? "\n" <blank_line>?
<trailing_space> ::= r" {1,3}"
<line_comment> ::= " " "//" r'[a-zA-Z0-9 ,.:!?()-]*'
<blank_line> ::= "\n"

# a comment on a line of its own, indented like the line after it
<note> ::= "//" r'[a-zA-Z0-9 ,.:!?()-]*' "\n"


# --- sections

<namespace_section> ::= "namespace " <reference> <eol>

<include_section> ::= "include" <eol> <include_line>{1,6}
<include_line> ::= <in1> <language_level> <eol>
<language_level> ::= <major_level> ("." (<minor_level> | "*"))?
<major_level> ::= "Boolean" | "Arithmetic" | "Type"
<minor_level> ::= "group-cardinality" | "feature-cardinality" | "aggregate-function" | "string-constraints"

<imports_section> ::= "imports" <eol> <import_line>{1,6}
<import_line> ::= <in1> <reference> (" as " <reference>)? <eol>

<features_section> ::= "features" <eol> <feature1>

<constraints_section> ::= "constraints" <eol> <constraint_line>{1,12}
<constraint_line> ::= (<in1> <note>)? <in1> <constraint> <eol>


# --- the feature tree, by depth

# (a root without groups is a model too, but Fandango would then make mostly those)
<feature1> ::= (<in1> <note>)? <in1> <feature_decl> <eol> <group2>{1,5}
<group2>   ::= <in2> <group_kind> <eol> <feature3>{1,8}
<feature3> ::= (<in3> <note>)? <in3> <feature_decl> <eol> <group4>{0,3}
<group4>   ::= <in4> <group_kind> <eol> <feature5>{1,6}
<feature5> ::= (<in5> <note>)? <in5> <feature_decl> <eol> <group6>{0,3}
<group6>   ::= <in6> <group_kind> <eol> <feature7>{1,5}
<feature7> ::= (<in7> <note>)? <in7> <feature_decl> <eol> <group8>{0,2}
<group8>   ::= <in8> <group_kind> <eol> <feature9>{1,5}
<feature9> ::= (<in9> <note>)? <in9> <feature_decl> <eol>

<group_kind> ::= "or" | "alternative" | "optional" | "mandatory" | <cardinality>

<feature_decl> ::= (<feature_type> " ")? <reference> <feature_cardinality>? (" " <attributes>)?
<feature_type> ::= "String" | "Integer" | "Boolean" | "Real"
<feature_cardinality> ::= " cardinality " <cardinality>

# one token: no spaces inside
<cardinality> ::= "[" <natural> (".." (<natural> | "*"))? "]"


# --- attributes

<attributes> ::= "{" (<attribute> (", " <attribute>){0,3})? "}"
<attribute> ::= <value_attribute> | <constraint_attribute>
<value_attribute> ::= <key> (" " <value>)?
<key> ::= <id>
<value> ::= <boolean> | <float> | <integer> | <string> | <attributes> | <vector>

<vector> ::= "[]" | "[" <vector_item> "]" | "[" <value> (", " <value>){1,3} "]"
# one value alone: anything but an integer right after the bracket
<vector_item> ::= <boolean> | <float> | <string> | <attributes> | <vector>

<constraint_attribute> ::= "constraint " <constraint> | "constraints " <constraint_list>
<constraint_list> ::= "[" (<constraint> (", " <constraint>){0,2})? "]"


# --- constraints

<constraint> ::= <unary_constraint> (<logical_operator> <unary_constraint>){0,3}
<unary_constraint> ::= "!" <unary_constraint> | <reference> | <equation> | "(" <constraint> ")"
<logical_operator> ::= " & " | " | " | " => " | " <=> " | "&" | "|" | "=>" | "<=>"

<equation> ::= <expression> <comparison> <expression>
<comparison> ::= " == " | " != " | " < " | " <= " | " > " | " >= " | "==" | "!=" | "<" | "<=" | ">" | ">="

<expression> ::= <term> (<additive_operator> <term>){0,2}
<term> ::= <primary> (<multiplicative_operator> <primary>){0,2}
<additive_operator> ::= " + " | " - " | "+" | "- "
<multiplicative_operator> ::= " * " | " / " | "*" | "/"
<primary> ::= <float> | <integer> | <string> | <aggregate> | <reference> | "(" <expression> ")"

<aggregate> ::= <two_argument_aggregate> | <one_argument_aggregate>
<two_argument_aggregate> ::= ("sum" | "avg") "(" (<reference> ", ")? <reference> ")"
<one_argument_aggregate> ::= ("len" | "floor" | "ceil") "(" <reference> ")"


# --- names and literals

<reference> ::= (<id> "."){0,2} <id>
<id> ::= <id_strict> | <id_strict> | <id_strict> | <id_quoted>

# ID_STRICT: a letter, then letters, digits and a few signs; never a keyword
<id_strict> ::= r"[a-zA-Z][a-zA-Z0-9_#%?;'\\]{0,7}" | r"[a-zA-Z][a-zA-Z0-9_]{8,30}"
where str(<id_strict>) not in KEYWORDS
# ID_NOT_STRICT: anything but a line end, a quote or a dot, between quotes
<id_quoted> ::= '"' r'[a-zA-Z0-9 _!?+*/-]{1,16}' '"'

<boolean> ::= "true" | "false"
<natural> ::= "0" | r'[1-9][0-9]{0,2}'
<integer> ::= "0" | "-"? r'[1-9][0-9]{0,4}'
<float> ::= "-"? r'[0-9]{0,3}\.[0-9]{1,3}'
<string> ::= "'" r"[a-zA-Z0-9 _.,:!?-]{1,16}" "'"

# what the lexer reads as something other than ID_STRICT
KEYWORDS = {
    "include", "features", "imports", "namespace", "as", "constraint", "constraints", "cardinality",
    "String", "Boolean", "Integer", "Real", "len", "sum", "avg", "floor", "ceil", "Type", "Arithmetic",
    "or", "alternative", "optional", "mandatory", "true", "false",
}
