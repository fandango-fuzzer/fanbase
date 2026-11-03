# XML documents whose parts sit at the edges of well-formedness: XML 1.0 and
# 1.1 declarations in both quote styles with several encodings and standalone;
# a DOCTYPE with SYSTEM and PUBLIC identifiers and an internal subset of
# element, attribute-list, entity (general, parameter and unparsed) and
# notation declarations; comments that keep away from "--", processing
# instructions that keep away from "?>", and CDATA sections that hold raw
# markup; character references to markup characters, to U+D7FF just below the
# surrogates, and to the supplementary planes (U+1F600); names with leading
# underscores, dots, dashes and namespace prefixes; white space around "=",
# xml:lang, xml:space, a default namespace and prefixed elements and
# attributes. Each start tag is tied to its end tag by a where constraint.
#
# TODO:
# * A DOCTYPE that names an external DTD makes a parser that loads it (Xerces
#   does) look for a file that is not there.
# * Entities and notations may have prefixed names, which a parser that checks
#   namespaces (Xerces, libxml2 2.14 and later) refuses, and system
#   identifiers may have a fragment ("#"), which libxml2 refuses.
# * The text is ASCII: other characters only come as character references.

<start> ::= <document>

# A document: an XML declaration, comments, processing instructions and
# white space, a DOCTYPE, and the root element
<document> ::= <xmldecl>? <misc>{0,3} <doctype>? <misc>{0,3} <root_element> <misc>{0,3}

# The XML declaration. The text is ASCII, so every encoding named reads it
# (none of two bytes a character)
<xmldecl>      ::= "<?xml" <version_info> <encoding_decl>? <sd_decl>? <s>? "?>"
<version_info> ::= <s> "version" <eq> <version_num>
<version_num>  ::= '"1.0"' | "'1.0'" | '"1.1"' | "'1.1'"
<encoding_decl>::= <s> "encoding" <eq> <enc_name>
<enc_name>     ::= '"UTF-8"' | "'utf-8'" | '"US-ASCII"' | '"ISO-8859-1"' | '"UTF-8"'
<sd_decl>      ::= <s> "standalone" <eq> <sd_val>
<sd_val>       ::= '"yes"' | '"no"' | "'yes'" | "'no'"

# Comments: no "--" inside, no "-" at the end
<misc> ::= <comment> | <pi> | <s>

<comment>      ::= "<!--" <comm_seg>{0,20} "-->"
<comm_seg>     ::= <commchar> | "-" <commchar>
<commchar>     ::= r'[a-zA-Z0-9 <>&/=:;!?()@$%*+_.,]'

# Processing instructions: the target is not "xml", and there is no "?" in
# the data
<pi>           ::= "<?" <pi_target> <pi_tail>? "?>"
<pi_target>    ::= "xml-stylesheet" | "php" | "target" | "pi-1" | "foo.bar"
<pi_tail>      ::= <s> <pichar>{0,20}
<pichar>       ::= r'[a-zA-Z0-9 <>&/=:;!()@$%*+_.,"-]'

# The DOCTYPE, named after the root element, and the internal subset
<doctype>      ::= "<!DOCTYPE" <s> "root" <ext_id_part>? <int_part>? <s>? ">"
<ext_id_part>  ::= <s> <external_id>
<external_id>  ::= "SYSTEM" <s> <sys_lit> | "PUBLIC" <s> <pub_lit> <s> <sys_lit>
<sys_lit>      ::= '"' <sys_chars> '"' | "'" <sys_chars> "'"
<sys_chars>    ::= r'[a-zA-Z0-9 ./:_#-]{0,15}'
<pub_lit>      ::= '"' <pub_chars> '"' | "'" <pub_chars> "'"
<pub_chars>    ::= r'[a-zA-Z0-9 ./:_()+,=?;!*#@$%-]{0,15}'

<int_part>     ::= <s>? "[" <markup_decl>{0,4} "]"
<markup_decl>  ::= <elementdecl> | <attlistdecl> | <entitydecl> \
                 | <notationdecl> | <comment> | <pi> | <s>

<elementdecl>  ::= "<!ELEMENT" <s> <decl_name> <s> <contentspec> <s>? ">"
<contentspec>  ::= "EMPTY" | "ANY" | "(#PCDATA)" | "(#PCDATA)*" | <children_spec>
<children_spec>::= "(" <cp> <seq_more>{0,3} ")" <occur>? | "(" <cp> <choice_more>{1,3} ")" <occur>?
<cp>           ::= <decl_name> <occur>?
<seq_more>    ::= "," <cp>
<choice_more> ::= "|" <cp>

<occur>        ::= "?" | "*" | "+"

<attlistdecl>  ::= "<!ATTLIST" <s> <decl_name> <attdef>{0,3} <s>? ">"
<attdef>       ::= <s> <decl_name> <s> <att_type> <s> <default_decl>
<att_type>     ::= "CDATA" | "ID" | "IDREF" | "IDREFS" | "ENTITY" | "ENTITIES" \
                 | "NMTOKEN" | "NMTOKENS" | <enum_type>
<enum_type>    ::= "(" <nmtoken> <enum_more>{0,3} ")"
<enum_more>    ::= "|" <nmtoken>
<nmtoken>      ::= r'[a-zA-Z0-9_.:-]{1,8}'
<default_decl> ::= "#REQUIRED" | "#IMPLIED" | "#FIXED" <s> <attvalue> | <attvalue>

# General, parameter and unparsed entities; their text has no "&" or "%"
<entitydecl>   ::= "<!ENTITY" <s> <decl_name> <s> <entity_value> <s>? ">" \
                 | "<!ENTITY" <s> "%" <s> <decl_name> <s> <entity_value> <s>? ">" \
                 | "<!ENTITY" <s> <decl_name> <s> <external_id> <ndata>? <s>? ">"
<ndata>        ::= <s> "NDATA" <s> <decl_name>
<entity_value> ::= '"' <ev_chars> '"' | "'" <ev_chars> "'"
<ev_chars>     ::= r'[a-zA-Z0-9 .,:;/=_@#()+ -]{0,15}'

<notationdecl> ::= "<!NOTATION" <s> <decl_name> <s> <notation_id> <s>? ">"
<notation_id>  ::= "SYSTEM" <s> <sys_lit> | "PUBLIC" <s> <pub_lit> <notn_sys>?
<notn_sys>     ::= <s> <sys_lit>

# Names in declarations, with and without a prefix
<decl_name>    ::= r'[a-zA-Z_][a-zA-Z0-9_.-]{0,6}' \
                 | r'[a-zA-Z_][a-zA-Z0-9_.-]{0,4}:[a-zA-Z_][a-zA-Z0-9_.-]{0,4}'

# The root declares the default namespace and the prefix x
<root_element> ::= "<root" <root_ns> <elem_attrs> ">" <content> "</root>" \
                 | "<root" <root_ns> <elem_attrs> "/>"
<root_ns>      ::= ' xmlns="urn:example:d" xmlns:x="urn:example:x"'

# Content and elements: the start and end tags are separate children, so
# that the constraint below can compare them
<content>      ::= <char_data>? <content_pair>{0,4}
<content_pair> ::= <content_item> <char_data>?
<content_item> ::= <element> | <reference> | <cdata> | <pi> | <comment>

<element>        ::= <paired_element> | <empty_element>
<paired_element> ::= "<" <sname> <elem_attrs> ">" <content> "</" <ename> ">"
<empty_element>  ::= "<" <sname> <elem_attrs> "/>"

<sname>     ::= <elem_name>
<ename>     ::= <elem_name>

# Names that are valid but unusual
<elem_name> ::= "a" | "b" | "item" | "child" | "x:leaf" | "_n" | "n.1" | "n-2"

# Attributes: each one has its own place, so none repeats
<elem_attrs> ::= <a_id>? <a_class>? <a_lang>? <a_space>? <a_nsdecl>? <a_xattr>?
<a_id>     ::= <s> "id"        <eq> <attvalue>
<a_class>  ::= <s> "class"     <eq> <attvalue>
<a_lang>   ::= <s> "xml:lang"  <eq> <lang_value>
<a_space>  ::= <s> "xml:space" <eq> <space_value>
<a_nsdecl> ::= <s> "xmlns:y"   <eq> '"urn:example:y"'
<a_xattr>  ::= <s> "x:attr"    <eq> <attvalue>
<lang_value>  ::= '"en"' | '"en-US"' | '"de"' | "'fr-CA'" | '"zh-Hant"'
<space_value> ::= '"default"' | '"preserve"' | "'default'"

# Attribute values in both quotes, with references and the other quote inside
<attvalue> ::= '"' <av_dq>{0,10} '"' | "'" <av_sq>{0,10} "'"
<av_dq>    ::= <ac_dq> | <reference>
<av_sq>    ::= <ac_sq> | <reference>
<ac_dq>    ::= r"[a-zA-Z0-9 .,:;/=_@#()+'?!-]"
<ac_sq>    ::= r'[a-zA-Z0-9 .,:;/=_@#()+"?!-]'

# Predefined entities, and character references to markup characters, a tab,
# accented letters, U+D7FF and U+1F600
<reference>  ::= <entity_ref> | <char_ref>
<entity_ref> ::= "&amp;" | "&lt;" | "&gt;" | "&apos;" | "&quot;"
<char_ref>   ::= "&#" <dec_code> ";" | "&#x" <hex_code> ";"
<dec_code>   ::= "65" | "97" | "233" | "8364" | "955" | "128512" | "9" | "60" | "38" | "32"
<hex_code>   ::= "41" | "263A" | "1F600" | "20AC" | "E9" | "D7FF" | "3C" | "26"

# Text without "<", "&" or "]" (so never "]]>"), and CDATA without "]"
<char_data> ::= <text_char>{1,5}
<text_char> ::= r"[a-zA-Z0-9 .,:;!?()@#$%*+/=_>\"'-]"

<cdata>      ::= "<![CDATA[" <cdata_char>{0,20} "]]>"
<cdata_char> ::= r'[a-zA-Z0-9 <>&/=:;!?()@#$%*+_.,"-]'

# White space
<s>  ::= r'[ \t\r\n]{1,3}'
<eq> ::= <s>? "=" <s>?

# Every start tag has the name of its end tag.
where forall <pe> in <paired_element>: str(<pe>.<sname>) == str(<pe>.<ename>)
