# Unix ar archives (.a) of one or more members whose header fields take the
# edge values: names that are the GNU symbol table (/), the GNU long-name
# table (//), a reference into it (/N, with N any fifteen digits), the BSD
# symbol table (__.SYMDEF), a BSD extended name (#1/N), a short GNU name
# ending in '/', or any sixteen printable characters; times, uids and gids of
# zero, the widest values, or blanks; and modes 100644, 100777, 0 or any six
# octal digits. Member data is 0 to 16 random bytes, its size written in full
# with leading zeros, and data of odd length is followed by a newline.
#
# TODO:
# * The names that point elsewhere (/N, #1/N) and the symbol and name tables
#   do not agree with anything in the archive, so most readers refuse most
#   files.

<start> ::= <magic> <member>+

<magic> ::= b'!<arch>\n'

<member> ::= <name> <mtime> <uid> <gid> <mode> <size_and_data>

# The name field: 16 bytes in every case
<name> ::= <n_symtab> | <n_strtab> | <n_longref> | <n_bsdsym> | <n_bsdext> | <n_short> | <n_plain>
<n_symtab>  ::= b'/               '
<n_strtab>  ::= b'//              '
<n_longref> ::= r'/[0-9]{15}'
<n_bsdsym>  ::= b'__.SYMDEF       '
<n_bsdext>  ::= r'#1/[0-9]{2} {11}'
<n_short>   ::= r'[a-z][a-z0-9_]{4}\.o/ {8}'
<n_plain>   ::= r'[!-~][ -~]{15}'

# Time (12), uid and gid (6) in decimal, mode (8) in octal: zero, the widest,
# blank
<mtime> ::= r'0 {11}' | r'[0-9]{12}' | r' {12}'
<uid>   ::= r'0 {5}'  | r'[0-9]{6}'  | r' {6}'
<gid>   ::= r'0 {5}'  | r'[0-9]{6}'  | r' {6}'
<mode>  ::= r'100644  ' | r'100777  ' | r'0 {7}' | r'[0-7]{6}  '

# The size (10 decimal digits), the end of the header, the data, and the
# newline that pads data of odd length: one alternative for each length, so
# that the size is the length of the data
<size_and_data> ::= <data_0> | <data_1> | <data_2> | <data_3> | <data_4> | <data_5> | <data_6> | <data_7> | <data_8> | <data_9> | <data_10> | <data_11> | <data_12> | <data_13> | <data_14> | <data_15> | <data_16>
<data_0>  ::= b'0000000000' <fmag>
<data_1>  ::= b'0000000001' <fmag> <byte> <pad>
<data_2>  ::= b'0000000002' <fmag> <byte>{2}
<data_3>  ::= b'0000000003' <fmag> <byte>{3} <pad>
<data_4>  ::= b'0000000004' <fmag> <byte>{4}
<data_5>  ::= b'0000000005' <fmag> <byte>{5} <pad>
<data_6>  ::= b'0000000006' <fmag> <byte>{6}
<data_7>  ::= b'0000000007' <fmag> <byte>{7} <pad>
<data_8>  ::= b'0000000008' <fmag> <byte>{8}
<data_9>  ::= b'0000000009' <fmag> <byte>{9} <pad>
<data_10> ::= b'0000000010' <fmag> <byte>{10}
<data_11> ::= b'0000000011' <fmag> <byte>{11} <pad>
<data_12> ::= b'0000000012' <fmag> <byte>{12}
<data_13> ::= b'0000000013' <fmag> <byte>{13} <pad>
<data_14> ::= b'0000000014' <fmag> <byte>{14}
<data_15> ::= b'0000000015' <fmag> <byte>{15} <pad>
<data_16> ::= b'0000000016' <fmag> <byte>{16}

<fmag> ::= b'`\n'
<pad>  ::= b'\n'
<byte> ::= rb'[\x00-\xff]'
