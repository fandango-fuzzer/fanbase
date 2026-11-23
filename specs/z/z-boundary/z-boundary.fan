# Files of Unix compress (.Z) at the edges of the format: every largest code
# width from 9 to 16 bits, with and without block mode; a header and nothing
# else (no data); CLEAR codes; and as many codes as it takes to widen them,
# stage by stage, from 9 bits up to the largest the header allows. The codes
# are all literal zeros, packed in groups of eight codes, which is how
# compress writes them: a group of width W is W bytes, and the width changes
# and CLEAR codes fall on group boundaries.
#
# TODO:
# * The codes are all literal zeros: none refers to the dictionary, and the
#   data is zeros.

<start> ::= <base_file> | <boundary_file> | <legacy_file> | <clear_file> | <growth_file>;

# Any flags byte, and up to eight literal codes
<base_file> ::= <magic> <legal_flags> <short_literal_stream>;
<magic> ::= b"\x1f\x9d";
<legal_flags> ::= b"\x09" | b"\x0a" | b"\x0b" | b"\x0c" | b"\x0d" | b"\x0e" | b"\x0f" | b"\x10" | b"\x89" | b"\x8a" | b"\x8b" | b"\x8c" | b"\x8d" | b"\x8e" | b"\x8f" | b"\x90";
<short_literal_stream> ::= b"" | b"\x00\x00" | b"\x00\x00\x00" | b"\x00\x00\x00\x00" | b"\x00\x00\x00\x00\x00" | b"\x00\x00\x00\x00\x00\x00" | b"\x00\x00\x00\x00\x00\x00\x00" | b"\x00\x00\x00\x00\x00\x00\x00\x00" | <zero9_group>;

# The smallest (9) and the largest (16) code width, and up to 32 groups of codes
<boundary_file> ::= <magic> <min_flags> <bounded_9bit_groups> | <magic> <max_flags> <bounded_9bit_groups>;
<min_flags> ::= b"\x09" | b"\x89";
<max_flags> ::= b"\x10" | b"\x90";
<bounded_9bit_groups> ::= <zero9_group>{1,32} <partial_zero9>?;
<partial_zero9> ::= b"\x00\x00" | b"\x00\x00\x00" | b"\x00\x00\x00\x00" | b"\x00\x00\x00\x00\x00" | b"\x00\x00\x00\x00\x00\x00" | b"\x00\x00\x00\x00\x00\x00\x00" | b"\x00\x00\x00\x00\x00\x00\x00\x00";

# Without block mode: the header alone, or up to 32 groups of codes
<legacy_file> ::= <magic> <nonblock_flags> | <magic> <nonblock_flags> <zero9_group>{1,32};
<nonblock_flags> ::= b"\x09" | b"\x0a" | b"\x0b" | b"\x0c" | b"\x0d" | b"\x0e" | b"\x0f" | b"\x10";

# Block mode, and CLEAR codes (256): seven literal zeros and a CLEAR are eight
# zero bytes and 0x80. After each the codes start again at 9 bits.
<clear_file> ::= <magic> <block_flags> <zero9_group>{0,4} <clear9_group> (<zero9_group>{1,4} <clear9_group>){0,3} <short_literal_stream>;
<block_flags> ::= b"\x89" | b"\x8a" | b"\x8b" | b"\x8c" | b"\x8d" | b"\x8e" | b"\x8f" | b"\x90";
<clear9_group> ::= b"\x00\x00\x00\x00\x00\x00\x00\x00\x80";

# Codes that widen: every code adds one to the dictionary, and each stage holds
# as many as it takes to fill one width (32 groups of 9-bit codes, 64 of 10-bit
# ones, and so on); the tail is one code of the next width. The header allows
# the widest code that the file has.
<growth_file> ::= <growth10> | <growth11> | <growth12> | <growth13> | <growth14> | <growth15> | <growth16>;
<growth10> ::= <magic> <flags10plus> <stage9> <tail10>;
<growth11> ::= <magic> <flags11plus> <stage9> <stage10> <tail11>;
<growth12> ::= <magic> <flags12plus> <stage9> <stage10> <stage11> <tail12>;
<growth13> ::= <magic> <flags13plus> <stage9> <stage10> <stage11> <stage12> <tail13>;
<growth14> ::= <magic> <flags14plus> <stage9> <stage10> <stage11> <stage12> <stage13> <tail14>;
<growth15> ::= <magic> <flags15plus> <stage9> <stage10> <stage11> <stage12> <stage13> <stage14> <tail15>;
<growth16> ::= <magic> <flags16> <stage9> <stage10> <stage11> <stage12> <stage13> <stage14> <stage15> <tail16>;

<flags10plus> ::= b"\x8a" | b"\x8b" | b"\x8c" | b"\x8d" | b"\x8e" | b"\x8f" | b"\x90";
<flags11plus> ::= b"\x8b" | b"\x8c" | b"\x8d" | b"\x8e" | b"\x8f" | b"\x90";
<flags12plus> ::= b"\x8c" | b"\x8d" | b"\x8e" | b"\x8f" | b"\x90";
<flags13plus> ::= b"\x8d" | b"\x8e" | b"\x8f" | b"\x90";
<flags14plus> ::= b"\x8e" | b"\x8f" | b"\x90";
<flags15plus> ::= b"\x8f" | b"\x90";
<flags16> ::= b"\x90";

<stage9> ::= <zero9_group>{32};
<stage10> ::= <zero10_group>{64};
<stage11> ::= <zero11_group>{128};
<stage12> ::= <zero12_group>{256};
<stage13> ::= <zero13_group>{512};
<stage14> ::= <zero14_group>{1024};
<stage15> ::= <zero15_group>{2048};

<tail10> ::= b"\x00\x00";
<tail11> ::= b"\x00\x00";
<tail12> ::= b"\x00\x00";
<tail13> ::= b"\x00\x00";
<tail14> ::= b"\x00\x00";
<tail15> ::= b"\x00\x00";
<tail16> ::= b"\x00\x00";

<zero9_group> ::= b"\x00\x00\x00\x00\x00\x00\x00\x00\x00";
<zero10_group> ::= b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
<zero11_group> ::= b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
<zero12_group> ::= b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
<zero13_group> ::= b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
<zero14_group> ::= b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
<zero15_group> ::= b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
