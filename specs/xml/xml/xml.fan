# XML 1.0 and 1.1 documents: an optional XML declaration (version, encoding,
# standalone), comments, processing instructions and white space around a
# DOCTYPE with an optional internal subset (element, attribute-list, entity
# and notation declarations, with content models, attribute types and
# defaults, general and parameter entities, external and unparsed entities)
# and the root element. Elements alpha to delta and a namespaced ns:item nest,
# each start tag paired with its end tag, with id, class, xml:lang and enabled
# attributes, character data, CDATA sections, comments, processing
# instructions, and predefined entity and character references.
#
# TODO:
# * Elements seldom nest more than a level or two in the files Fandango makes:
#   most hold text and references, or nothing.
# * The internal subset declares elements other than those the document uses,
#   so a validating parser would refuse it; and its entities are never
#   referenced.

<start> ::= <document>

# The document and its prolog
<document> ::= <xml_decl>? <misc>* <doctype>? <misc>* <alpha_element> <misc>*
<xml_decl> ::= "<?xml version=\"" <version_num> "\"" <encoding_decl>? <standalone_decl>? "?>"
<version_num> ::= "1.0" | "1.1"
<encoding_decl> ::= " encoding=\"" <encoding_name> "\""
<encoding_name> ::= "UTF-8" | "US-ASCII"
<standalone_decl> ::= " standalone=\"" <yes_no> "\""
<yes_no> ::= "yes" | "no"
<misc> ::= <ws> | <comment> | <pi>

# The DOCTYPE, its internal subset, and the declarations in it
<doctype> ::= "<!DOCTYPE alpha" <int_subset>? <s>? ">"
<external_id> ::= " SYSTEM " <system_literal> | " PUBLIC " <pubid_literal> " " <system_literal>
<int_subset> ::= " [" <markup_decl>* "]"
<markup_decl> ::= <element_decl> | <attlist_decl> | <entity_decl> | <notation_decl> | <pi> | <comment> | <ws>
<element_decl> ::= "<!ELEMENT " <name> <s> <contentspec> <s>? ">"
<contentspec> ::= "EMPTY" | "ANY" | <mixed> | <children>
<children> ::= <choice> | <seq>
<cp> ::= <name> <occurrence>?
<choice> ::= "(" <cp> ("|" <cp>)+ ")" <occurrence>?
<seq> ::= "(" <cp> ("," <cp>)+ ")" <occurrence>?
<occurrence> ::= "?" | "*" | "+"
<mixed> ::= "(#PCDATA)" | "(#PCDATA|" <name> ("|" <name>)* ")*"
<attlist_decl> ::= "<!ATTLIST " <name> <att_def>+ <s>? ">"
<att_def> ::= <s> <name> <s> <att_type> <s> <default_decl>
<att_type> ::= <string_type> | <tokenized_type> | <enumerated_type>
<string_type> ::= "CDATA"
<tokenized_type> ::= "ID" | "IDREF" | "IDREFS" | "ENTITY" | "ENTITIES" | "NMTOKEN" | "NMTOKENS"
<enumerated_type> ::= <notation_type> | <enumeration>
<notation_type> ::= "NOTATION " <s>? "(" <s>? <name> (<s>? "|" <s>? <name>)+ <s>? ")"
<enumeration> ::= "(" <s>? <nmtoken> (<s>? "|" <s>? <nmtoken>)+ <s>? ")"
<default_decl> ::= "#REQUIRED" | "#IMPLIED" | ("#FIXED" <s>)? <att_value>
<entity_decl> ::= <ge_decl> | <pe_decl>
<ge_decl> ::= "<!ENTITY " <name> <s> <entity_def> <s>? ">"
<pe_decl> ::= "<!ENTITY % " <name> <s> <pe_def> <s>? ">"
<entity_def> ::= <entity_value> | <external_id> <ndata_decl>?
<pe_def> ::= <entity_value> | <external_id>
<ndata_decl> ::= <s> "NDATA" <s> <name>
<notation_decl> ::= "<!NOTATION " <name> <s> (<external_id> | "PUBLIC " <pubid_literal>) <s>? ">"

# Elements: every start tag has its own end tag, so they nest and their names
# match
<element> ::= <alpha_element> | <beta_element> | <gamma_element> | <delta_element> | <ns_element>
<alpha_element> ::= "<alpha" <attributes> <s>? "/>" | "<alpha" <attributes> <s>? ">" <content> "</alpha>"
<beta_element> ::= "<beta" <attributes> <s>? "/>" | "<beta" <attributes> <s>? ">" <content> "</beta>"
<gamma_element> ::= "<gamma" <attributes> <s>? "/>" | "<gamma" <attributes> <s>? ">" <content> "</gamma>"
<delta_element> ::= "<delta" <attributes> <s>? "/>" | "<delta" <attributes> <s>? ">" <content> "</delta>"
<ns_element> ::= "<ns:item xmlns:ns=\"urn:example\"" <attributes> <s>? "/>" | "<ns:item xmlns:ns=\"urn:example\"" <attributes> <s>? ">" <content> "</ns:item>"
<attributes> ::= <id_attr>? <class_attr>? <lang_attr>? <flag_attr>?
<id_attr> ::= <s> "id" <s>? "=" <s>? <att_value>
<class_attr> ::= <s> "class" <s>? "=" <s>? <att_value>
<lang_attr> ::= <s> "xml:lang" <s>? "=" <s>? <att_value>
<flag_attr> ::= <s> "enabled" <s>? "=" <s>? <att_value>
<att_value> ::= "\"" <double_quoted_value>* "\"" | "'" <single_quoted_value>* "'"
<double_quoted_value> ::= <reference> | r'[^<&\"]{1,24}'
<single_quoted_value> ::= <reference> | r"[^<&']{1,24}"
<content> ::= (<char_data> | <element> | <reference> | <cdata> | <pi> | <comment>)*
<char_data> ::= r'[^<>&\]]{1,48}'
<cdata> ::= "<![CDATA[" <cdata_text>? "]]>"
<cdata_text> ::= r'[^\]]{1,48}' | "]" r'[^\]]{0,47}' | "]]" r'[^>]{1,46}'

# References, processing instructions, comments, literals, names and white
# space
<reference> ::= <entity_ref> | <char_ref>
<entity_ref> ::= "&amp;" | "&lt;" | "&gt;" | "&apos;" | "&quot;"
<char_ref> ::= "&#" <decimal> ";" | "&#x" <hex> ";"
<decimal> ::= "9" | "10" | "13" | "32" | "65" | "169" | "8364"
<hex> ::= "9" | "A" | "D" | "20" | "41" | "A9" | "20AC"
<pi> ::= "<?" <pitarget> (<s> <pi_data>)? "?>"
<pitarget> ::= "p" | "proc" | "stylesheet"
<pi_data> ::= r'[^?]{1,48}' | "?" r'[^>]{1,47}'
<comment> ::= "<!--" <comment_text>? "-->"
<comment_text> ::= r'[^-]{1,48}' | "-" r'[^-]{1,47}'
<entity_value> ::= "\"" <entity_value_dq>* "\"" | "'" <entity_value_sq>* "'"
<entity_value_dq> ::= <reference> | r'[^%&\"]{1,24}'
<entity_value_sq> ::= <reference> | r"[^%&']{1,24}"
<parameter_entity_ref> ::= "%" <name> ";"
<system_literal> ::= "\"" r'[^\"#]{1,48}' "\"" | "'" r"[^'#]{1,48}" "'"
<pubid_literal> ::= "\"" <pubid_char>* "\"" | "'" <pubid_char_sq>* "'"
<pubid_char> ::= r'[ A-Za-z0-9\r\n\-\'\(\)\+,\./:=\?;!\*#@$_%]{1,24}'
<pubid_char_sq> ::= r'[ A-Za-z0-9\r\n\-\(\)\+,\./:=\?;!\*#@$_%]{1,24}'
<name> ::= r'[A-Za-z_][A-Za-z0-9._-]{0,31}'
<nmtoken> ::= r'[A-Za-z0-9._:-]{1,32}'
<s> ::= r'[ \t\r\n]+'
<ws> ::= <s>
