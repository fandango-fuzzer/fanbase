# Same as uvl, at UVL's Boolean language level only: what most feature-model
# tools read. Features are untyped and have no cardinality; constraints are
# propositional (no equations, arithmetic or aggregates), and attributes hold
# plain values. The include block, if there is one, names Boolean only.

include("uvl/uvl.fan")

<language_level> ::= "Boolean"

<feature_decl> ::= <reference> (" " <attributes>)?
<group_kind> ::= "or" | "alternative" | "optional" | "mandatory" | <cardinality>

<unary_constraint> ::= "!" <unary_constraint> | <reference> | "(" <constraint> ")"

<attribute> ::= <value_attribute>
