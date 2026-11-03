# XML documents of three kinds, of which those with a DOCTYPE are also valid
# against it: ordinary documents, a root element with namespace declarations,
# xml:lang, xml:space, xml:base and xml:id, and content of text, references,
# comments, processing instructions, CDATA sections and child elements; DTD
# documents, whose internal subset declares elements with EMPTY, ANY, mixed
# and child content models, attributes of the types ID, NMTOKENS, ENTITY and
# NOTATION and an enumeration with defaults, general entities that refer to
# others, parameter entities, external and unparsed entities and notations,
# and a root that obeys all of it; and a document of uncommon constructs next
# to each other, with its own DTD, elements twelve deep, character references
# at the edges of the Unicode ranges XML allows, and a namespace declared on a
# child. Every byte is ASCII.
#
# TODO:
# * The DTDs and much of the content are fixed text: what varies is which
#   parts a document has, the names, the text and the references.

# An ordinary document, a document with an internal DTD, or the document of
# uncommon constructs
<start> ::= <ordinary_document> | <doctype_document> | <edge_document>

<ordinary_document> ::= <prolog> <document_element> <trailing_misc>
<doctype_document> ::= <xml_decl>? <leading_misc> <doctype_decl> <between_misc> <dtd_root_element> <trailing_misc>
<edge_document> ::= <edge_xml_decl> <edge_doctype_decl>? <edge_root> <trailing_misc>

# The prolog: an XML declaration, comments, processing instructions, white
# space
<prolog> ::= <xml_decl>? <leading_misc>
<leading_misc> ::= <misc>{0,2}
<between_misc> ::= <misc>{0,2}
<trailing_misc> ::= <misc>{0,2}
<misc> ::= <xml_space> | <comment> | <processing_instruction>
<xml_space> ::= r'[ \t\r\n]{1,3}'
<linebreak> ::= "\n" | "\r\n"

<xml_decl> ::= "<?xml version=\"" <xml_version> "\"" <encoding_decl>? <standalone_decl>? "?>" <linebreak>?
<xml_version> ::= r'1\.[01]'
where str(<xml_version>) == "1.0" or str(<xml_version>) == "1.1"
<encoding_decl> ::= " encoding=\"" <encoding_name> "\""
<encoding_name> ::= "UTF-8" | "utf-8" | "US-ASCII" | "ISO-8859-1"
<standalone_decl> ::= " standalone=\"" <standalone_value> "\""
<standalone_value> ::= "yes" | "no"
<edge_xml_decl> ::= "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n"

# The root of an ordinary document: its end tag is tied to its start tag by
# a constraint
<document_element> ::= <paired_full_element> | <paired_empty_element> | <root_element>
<paired_full_element> ::= "<" <open_name> <root_attributes> ">" <general_content> "</" <close_name> ">"
where str(<open_name>) == str(<close_name>)
<paired_empty_element> ::= "<" <empty_open_name> <root_attributes> "/>"
where len(str(<empty_open_name>)) >= 2 and len(str(<empty_open_name>)) <= 9
<open_name> ::= "r" r'[A-Za-z_][A-Za-z0-9_.-]{0,7}'
<close_name> ::= "r" r'[A-Za-z_][A-Za-z0-9_.-]{0,7}'
<empty_open_name> ::= "e" r'[A-Za-z_][A-Za-z0-9_.-]{0,7}'

<root_element> ::= "<root" <root_attributes> ">" <general_content> "</root>" | "<root" <root_attributes> "/>"
<root_attributes> ::= <default_namespace_attr>? <prefixed_namespace_attr>? <xml_lang_attr>? <xml_space_attr>? <xml_base_attr>? <xml_id_attr>? <ordinary_attrs>
<default_namespace_attr> ::= " xmlns=\"urn:example:default\""
<prefixed_namespace_attr> ::= " xmlns:p=\"urn:example:edge\""
<xml_lang_attr> ::= " xml:lang=\"" <language_tag> "\""
<language_tag> ::= "en" | "en-US" | "de-CH-1901" | "i-klingon" | "x-private"
<xml_space_attr> ::= " xml:space=\"" <space_mode> "\""
<space_mode> ::= "default" | "preserve"
<xml_base_attr> ::= " xml:base=\"https://example.test/a/../b?x=1&amp;y=2\""
<xml_id_attr> ::= " xml:id=\"root-id\""
<ordinary_attrs> ::= <id_attr>? <class_attr>? <empty_attr>? <single_quoted_attr>? <escaped_attr>?
<id_attr> ::= " id=\"n0\""
<class_attr> ::= " class=\"alpha beta\""
<empty_attr> ::= " empty=\"\""
<single_quoted_attr> ::= " quote='single'"
<escaped_attr> ::= " escaped=\"&quot;&apos;&lt;&gt;&amp;&#xA;\""

# Content: up to four pieces, child elements written out to a fixed depth
<general_content> ::= <content_piece>{0,4}
<content_piece> ::= <character_data> | <reference> | <comment> | <processing_instruction> | <cdata_section> | <empty_child> | <text_child> | <mixed_child> | <namespace_child> | <namespace_reset_child> | <deep_nesting>
<character_data> ::= r'[A-Za-z0-9 .,;:_-]{1,16}' | "\n  "
<reference> ::= <predefined_entity_ref> | <decimal_char_ref> | <hex_char_ref>
<predefined_entity_ref> ::= "&amp;" | "&lt;" | "&gt;" | "&apos;" | "&quot;"
<decimal_char_ref> ::= "&#" <decimal_char_code> ";"
<decimal_char_code> ::= r'[0-9]{2,3}'
where int(<decimal_char_code>) >= 32 and int(<decimal_char_code>) <= 126
<hex_char_ref> ::= "&#x9;" | "&#xA;" | "&#xD;" | "&#x20;" | "&#x7E;" | "&#xA0;" | "&#xD7FF;" | "&#xE000;" | "&#xFFFD;" | "&#x10000;" | "&#x10FFFF;"

# Comments, processing instructions and CDATA sections
<comment> ::= "<!--comment-->" | "<!-- spaced comment -->" | "<!--boundary- -->"
<processing_instruction> ::= "<?app?>" | "<?app mode=\"edge\"?>" | "<?legacy data with ? marks?>"
<cdata_section> ::= "<![CDATA[]]>" | "<![CDATA[raw <tag> & entity-like text]]>" | "<![CDATA[brackets ] and ]] stay data]]>"

<empty_child> ::= "<empty/>" | "<empty />"
<text_child> ::= "<text>" <textual_content> "</text>"
<textual_content> ::= <character_data> | <character_data> <reference> <character_data>
<mixed_child> ::= "<mixed>" <character_data>? "<em>" <character_data> "</em>" <reference>? <character_data>? "</mixed>"
<namespace_child> ::= "<p:item xmlns:p=\"urn:example:edge\" p:flag=\"yes\"/>"
<namespace_reset_child> ::= "<plain xmlns=\"\">" <character_data> "</plain>"

# Twelve elements, one inside the other
<deep_nesting> ::= "<d0>" <depth_1> "</d0>"
<depth_1> ::= "<d1>" <depth_2> "</d1>"
<depth_2> ::= "<d2>" <depth_3> "</d2>"
<depth_3> ::= "<d3>" <depth_4> "</d3>"
<depth_4> ::= "<d4>" <depth_5> "</d4>"
<depth_5> ::= "<d5>" <depth_6> "</d5>"
<depth_6> ::= "<d6>" <depth_7> "</d6>"
<depth_7> ::= "<d7>" <depth_8> "</d7>"
<depth_8> ::= "<d8>" <depth_9> "</d8>"
<depth_9> ::= "<d9>" <depth_10> "</d9>"
<depth_10> ::= "<d10>" <depth_11> "</d10>"
<depth_11> ::= "<d11 boundary=\"max\">" <character_data>? "</d11>"

# An internal subset, and a root element valid against it (ID, ENTITY and
# NOTATION attributes included)
<doctype_decl> ::= "<!DOCTYPE root [\n" <dtd_element_decls> <dtd_attlist_decl> <dtd_general_entities> <dtd_parameter_entities> <dtd_notation_decls> "]>" <linebreak>?
<dtd_element_decls> ::= "<!ELEMENT root ANY>\n<!ELEMENT item (#PCDATA|em|empty)*>\n<!ELEMENT em (#PCDATA)>\n<!ELEMENT empty EMPTY>\n<!ELEMENT unused (head,(body|tail)?,note*)>\n<!ELEMENT head (#PCDATA)>\n<!ELEMENT body (#PCDATA)>\n<!ELEMENT tail (#PCDATA)>\n<!ELEMENT note EMPTY>\n"
<dtd_attlist_decl> ::= "<!ATTLIST item\n  id ID #IMPLIED\n  status (new|old|archived) \"new\"\n  tokens NMTOKENS #IMPLIED\n  xml:space (default|preserve) #IMPLIED\n  logo ENTITY #IMPLIED\n  format NOTATION (png|svg) #IMPLIED>\n"
<dtd_general_entities> ::= "<!ENTITY writer \"Ada Lovelace\">\n<!ENTITY legal \"Copyright &#169; &writer;\">\n<!ENTITY ext PUBLIC \"-//Example//TEXT Legacy V1.0//EN\" \"legacy.txt\">\n<!ENTITY logo SYSTEM \"logo.bin\" NDATA png>\n"
<dtd_parameter_entities> ::= "<!ENTITY % local \"\">\n%local;\n<!ENTITY % external SYSTEM \"legacy-parameter.ent\">\n"
<dtd_notation_decls> ::= "<!NOTATION png SYSTEM \"image/png\">\n<!NOTATION svg PUBLIC \"image/svg+xml\">\n"
<dtd_root_element> ::= "<root>" <dtd_text>? <dtd_item>? <dtd_empty>? <comment>? <processing_instruction>? "</root>"
<dtd_text> ::= "DTD " | "&writer; " | "&legal; "
<dtd_item> ::= "<item id=\"i1\" status=\"archived\" tokens=\"one two three\" xml:space=\"preserve\" logo=\"logo\" format=\"png\">" <dtd_item_content> "</item>"
<dtd_item_content> ::= "text " "<em>emphasis</em>" " &writer; " "<empty/>"
<dtd_empty> ::= "<empty/>"

# The document of uncommon constructs: when it has its DOCTYPE, the whole
# namespaced tree is valid against it
<edge_doctype_decl> ::= "<!DOCTYPE edge [\n" <edge_dtd_elements> <edge_dtd_attributes> "<!ENTITY old \"legacy\">\n<!NOTATION bin SYSTEM \"application/octet-stream\">\n<!ENTITY payload SYSTEM \"payload.bin\" NDATA bin>\n]>\n"
<edge_dtd_elements> ::= "<!ELEMENT edge ANY>\n<!ELEMENT q:leaf EMPTY>\n<!ELEMENT plain (#PCDATA)>\n<!ELEMENT d0 (d1)>\n<!ELEMENT d1 (d2)>\n<!ELEMENT d2 (d3)>\n<!ELEMENT d3 (d4)>\n<!ELEMENT d4 (d5)>\n<!ELEMENT d5 (d6)>\n<!ELEMENT d6 (d7)>\n<!ELEMENT d7 (d8)>\n<!ELEMENT d8 (d9)>\n<!ELEMENT d9 (d10)>\n<!ELEMENT d10 (d11)>\n<!ELEMENT d11 (#PCDATA)>\n"
<edge_dtd_attributes> ::= "<!ATTLIST edge xmlns CDATA #IMPLIED xmlns:q CDATA #IMPLIED xml:lang NMTOKEN #IMPLIED xml:space (default|preserve) #IMPLIED xml:base CDATA #IMPLIED xml:id ID #IMPLIED empty CDATA #IMPLIED escaped CDATA #IMPLIED>\n<!ATTLIST q:leaf q:flag CDATA #IMPLIED xmlns:q CDATA #IMPLIED>\n<!ATTLIST plain xmlns CDATA #IMPLIED>\n<!ATTLIST d11 boundary CDATA #IMPLIED>\n"
<edge_root> ::= "<edge xmlns=\"urn:example:default\" xmlns:q=\"urn:example:q\" xml:lang=\"de-CH-1901\" xml:space=\"preserve\" xml:base=\"urn:edge:base\" xml:id=\"edge-root\" empty=\"\" escaped=\"&quot;&apos;&lt;&gt;&amp;\">" <edge_content> "</edge>"
<edge_content> ::= "<?preflight mode=\"strict\"?>" "<!--adjacent markup-->" "<![CDATA[<raw attr='1'>&not-an-entity;</raw>]]>" "&#x9;&#xA;&#xD;&#x20;&#xD7FF;&#xE000;&#xFFFD;&#x10000;&#x10FFFF;" "<q:leaf q:flag=\"1\" xmlns:q=\"urn:example:q\"/>" "<plain xmlns=\"\">no default namespace</plain>" <deep_nesting>
