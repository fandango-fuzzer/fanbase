# Unix ar archives (.a) in each of the variants that tools write: System V
# with short names ending in '/'; BSD with space-padded names and #1/N names
# whose N bytes come first in the data; GNU with a // table of long names and
# a /0 reference to it; archives with a symbol table first (GNU / and /SYM64/,
# BSD __.SYMDEF and __.SYMDEF_64, sorted or not); Microsoft COFF archives with
# their two linker members; GNU thin archives; and an archive with an archive
# as its member. Every member is a 60-byte header and its data, padded to an
# even length with a newline. The sizes of members and of BSD names, and the
# padding, are tied to the data by where constraints; the symbol tables are
# written out, offsets included.
#
# TODO:
# * Thin archives name a member that is outside the archive, and it is not
#   there, so GNU ar and libarchive refuse them.
# * The symbol tables index one symbol, sym, and the member they point to is
#   always four bytes.

<start> ::= (
      <posix_archive>
    | <bsd_archive>
    | <gnu_long_name_archive>
    | <gnu_index32_archive>
    | <gnu_index64_archive>
    | <bsd_index32_archive>
    | <bsd_index64_archive>
    | <coff_archive>
    | <thin_archive>
    | <nested_archive>
);

# Fields that every header has
<archive_magic> ::= b'!<arch>\n';
<thin_magic> ::= b'!<thin>\n';
<header_trailer> ::= b'`\n';

# The time (12 bytes), uid and gid (6) are decimal digits padded with spaces
<date_field> ::= rb'[0-9]{1} {11}' | rb'[0-9]{2} {10}' | rb'[0-9]{3} {9}' | rb'[0-9]{4} {8}' | rb'[0-9]{5} {7}' | rb'[0-9]{6} {6}' | rb'[0-9]{7} {5}' | rb'[0-9]{8} {4}' | rb'[0-9]{9} {3}' | rb'[0-9]{10} {2}';

<uid_field> ::= rb'[0-9]{1} {5}' | rb'[0-9]{2} {4}' | rb'[0-9]{3} {3}' | rb'[0-9]{4} {2}' | rb'[0-9]{5} {1}';

<gid_field> ::= rb'[0-9]{1} {5}' | rb'[0-9]{2} {4}' | rb'[0-9]{3} {3}' | rb'[0-9]{4} {2}' | rb'[0-9]{5} {1}';

# The mode is octal; these are regular files
<mode_field> ::= b'100444  ' | b'100600  ' | b'100644  ' | b'100664  ' | b'100755  ' | b'100775  ';

<size_field> ::= <size_digits> <size_spaces>
where len(str(<size_digits>)) + len(str(<size_spaces>)) == 10
where 0 <= int(str(<size_digits>)) <= 999;
<size_digits> ::= rb'[0-9]{1,3}';
<size_spaces> ::= rb' {7,9}';

<short_name_field> ::= <short_name> b'/' <short_name_spaces>
where len(str(<short_name>)) + 1 + len(str(<short_name_spaces>)) == 16;
<short_name> ::= rb'[A-Za-z][A-Za-z0-9_.-]{0,13}';
<short_name_spaces> ::= rb' {1,14}';

<bsd_short_name_field> ::= <bsd_short_name> <bsd_short_name_spaces>
where len(str(<bsd_short_name>)) + len(str(<bsd_short_name_spaces>)) == 16;
<bsd_short_name> ::= rb'[A-Za-z][A-Za-z0-9_.-]{0,14}';
<bsd_short_name_spaces> ::= rb' {1,15}';

<member_data> ::= rb'[\x00-\xff]{0,24}';
<member_pad> ::= b'' | b'\n';

# System V: short names, any number of members
<posix_archive> ::= <archive_magic> <posix_member>+;
<posix_member> ::= (
    <short_name_field> <date_field> <uid_field> <gid_field> <mode_field>
    <size_field> <header_trailer> <member_data> <member_pad>
)
where int(str(<size_field>)) == len(str(<member_data>))
where ((len(str(<member_data>)) % 2 == 0 and len(str(<member_pad>)) == 0)
    or (len(str(<member_data>)) % 2 == 1 and len(str(<member_pad>)) == 1));

# BSD: names padded with spaces, or #1/N, where the N bytes of the name
# start the data and are counted in its size
<bsd_archive> ::= <archive_magic> (<bsd_short_member> | <bsd_extended_member>)+;
<bsd_short_member> ::= (
    <bsd_short_name_field> <date_field> <uid_field> <gid_field> <mode_field>
    <bsd_short_size_field> <header_trailer> <bsd_short_data> <bsd_short_pad>
)
where int(str(<bsd_short_size_field>)) == len(str(<bsd_short_data>))
where ((len(str(<bsd_short_data>)) % 2 == 0 and len(str(<bsd_short_pad>)) == 0)
    or (len(str(<bsd_short_data>)) % 2 == 1 and len(str(<bsd_short_pad>)) == 1));
<bsd_short_size_field> ::= <size_field>;
<bsd_short_data> ::= <member_data>;
<bsd_short_pad> ::= <member_pad>;

<bsd_extended_member> ::= (
    b'#1/' <bsd_name_length> b'           '
    <date_field> <uid_field> <gid_field> <mode_field>
    <bsd_extended_size_field> <header_trailer>
    <bsd_extended_name> <bsd_extended_data> <bsd_extended_pad>
)
where int(str(<bsd_name_length>)) == len(str(<bsd_extended_name>))
where int(str(<bsd_extended_size_field>)) == (len(str(<bsd_extended_name>)) + len(str(<bsd_extended_data>)))
where ((((len(str(<bsd_extended_name>)) + len(str(<bsd_extended_data>))) % 2) == 0
        and len(str(<bsd_extended_pad>)) == 0)
    or (((len(str(<bsd_extended_name>)) + len(str(<bsd_extended_data>))) % 2) == 1
        and len(str(<bsd_extended_pad>)) == 1));
<bsd_name_length> ::= rb'[1-9][0-9]';
<bsd_extended_name> ::= rb'[A-Za-z][A-Za-z0-9_.-]{15,19}';
<bsd_extended_size_field> ::= <size_field>;
<bsd_extended_data> ::= <member_data>;
<bsd_extended_pad> ::= <member_pad>;

# GNU: a // table holding one long name at offset 0 (25 bytes, so a
# newline follows that its size does not count), and a member named /0
<gnu_long_name_archive> ::= (
    <archive_magic>
    b'//              ' <date_field> <uid_field> <gid_field> <mode_field>
    b'25        ' <header_trailer> <gnu_long_name_table> b'\n'
    b'/0              ' <date_field> <uid_field> <gid_field> <mode_field>
    <gnu_referenced_size_field> <header_trailer>
    <gnu_referenced_data> <gnu_referenced_pad>
)
where int(str(<gnu_referenced_size_field>)) == len(str(<gnu_referenced_data>))
where ((len(str(<gnu_referenced_data>)) % 2 == 0 and len(str(<gnu_referenced_pad>)) == 0)
    or (len(str(<gnu_referenced_data>)) % 2 == 1 and len(str(<gnu_referenced_pad>)) == 1));
<gnu_long_name_table> ::= b'very-long-object-name.o/\n';
<gnu_referenced_size_field> ::= <size_field>;
<gnu_referenced_data> ::= <member_data>;
<gnu_referenced_pad> ::= <member_pad>;

# GNU symbol tables: one symbol, sym, at the member header that follows,
# 80 bytes in (8 of magic, 60 of header, 12 of table); /SYM64/ has 64-bit
# offsets, and its member is at 88. Big-endian
<gnu_index32_archive> ::= (
    <archive_magic>
    b'/               ' <date_field> <uid_field> <gid_field> <mode_field>
    b'12        ' <header_trailer> <gnu32_symbol_table>
    <indexed32_member>
);
<gnu32_symbol_table> ::= b'\x00\x00\x00\x01\x00\x00\x00\x50sym\x00';
<indexed32_member> ::= (
    b'indexed.o/      ' <date_field> <uid_field> <gid_field> <mode_field>
    b'4         ' <header_trailer> b'OBJ\x00'
);

<gnu_index64_archive> ::= (
    <archive_magic>
    b'/SYM64/         ' <date_field> <uid_field> <gid_field> <mode_field>
    b'20        ' <header_trailer> <gnu64_symbol_table>
    <indexed64_member>
);
<gnu64_symbol_table> ::= b'\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x58sym\x00';
<indexed64_member> ::= (
    b'indexed64.o/    ' <date_field> <uid_field> <gid_field> <mode_field>
    b'4         ' <header_trailer> b'OBJ\x00'
);

# BSD ranlib tables, little-endian: the size of the table (8), one entry
# (string index 0, member at 88), the size of the strings (4) and sym
<bsd_index32_archive> ::= (
    <archive_magic> <bsd_symdef32_name>
    <date_field> <uid_field> <gid_field> <mode_field>
    b'20        ' <header_trailer> <bsd32_ranlib_table>
    <bsd_indexed32_member>
);
<bsd_symdef32_name> ::= b'__.SYMDEF       ' | b'__.SYMDEF SORTED';
<bsd32_ranlib_table> ::= b'\x08\x00\x00\x00\x00\x00\x00\x00\x58\x00\x00\x00\x04\x00\x00\x00sym\x00';
<bsd_indexed32_member> ::= (
    b'bsdindex.o      ' <date_field> <uid_field> <gid_field> <mode_field>
    b'4         ' <header_trailer> b'OBJ\x00'
);

# __.SYMDEF_64: 64-bit entries, the member at 96; the sorted one is named
# #1/19, so its 19 bytes of name are in the data, and the member is at 116
<bsd_index64_archive> ::= (
    <bsd_index64_archive_unsorted>
    | <bsd_index64_archive_sorted>
);
<bsd_index64_archive_unsorted> ::= (
    <archive_magic> b'__.SYMDEF_64    '
    <date_field> <uid_field> <gid_field> <mode_field>
    b'28        ' <header_trailer> <bsd64_ranlib_table>
    <bsd_indexed64_member>
);
<bsd64_ranlib_table> ::= b'\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x60\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00sym\x00';
<bsd_index64_archive_sorted> ::= (
    <archive_magic> b'#1/19           '
    <date_field> <uid_field> <gid_field> <mode_field>
    b'47        ' <header_trailer> b'__.SYMDEF_64 SORTED'
    <bsd64_sorted_ranlib_table> b'\n'
    <bsd_indexed64_member>
);
<bsd64_sorted_ranlib_table> ::= b'\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x74\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00sym\x00';
<bsd_indexed64_member> ::= (
    b'bsdindex64.o    ' <date_field> <uid_field> <gid_field> <mode_field>
    b'4         ' <header_trailer> b'OBJ\x00'
);

# Microsoft COFF: the first linker member (big-endian) and the second
# (little-endian) both index sym at the object member's header, 158 bytes
# in (8 + 72 + 78)
<coff_archive> ::= (
    <archive_magic>
    b'/               ' <date_field> <uid_field> <gid_field> <mode_field>
    b'12        ' <header_trailer> <coff_first_linker>
    b'/               ' <date_field> <uid_field> <gid_field> <mode_field>
    b'18        ' <header_trailer> <coff_second_linker>
    <coff_object_member>
);
<coff_first_linker> ::= b'\x00\x00\x00\x01\x00\x00\x00\x9esym\x00';
<coff_second_linker> ::= b'\x01\x00\x00\x00\x9e\x00\x00\x00\x01\x00\x00\x00\x01\x00sym\x00';
<coff_object_member> ::= (
    b'coff.obj/       ' <date_field> <uid_field> <gid_field> <mode_field>
    b'4         ' <header_trailer> b'COFF'
);

# GNU thin archive: the // table, and a member /0 whose data is a file
# outside the archive, so nothing follows its header
<thin_archive> ::= (
    <thin_magic>
    b'//              ' <date_field> <uid_field> <gid_field> <mode_field>
    b'25        ' <header_trailer> <gnu_long_name_table> b'\n'
    b'/0              ' <date_field> <uid_field> <gid_field> <mode_field>
    <thin_external_size_field> <header_trailer>
)
where 0 <= int(str(<thin_external_size_field>)) <= 999;
<thin_external_size_field> ::= <size_field>;

# An archive whose member is an archive of one member
<nested_archive> ::= (
    <archive_magic>
    b'nested.a/       ' <date_field> <uid_field> <gid_field> <mode_field>
    <nested_size_field> <header_trailer> <embedded_archive> <nested_pad>
)
where int(str(<nested_size_field>)) == len(str(<embedded_archive>))
where ((len(str(<embedded_archive>)) % 2 == 0 and len(str(<nested_pad>)) == 0)
    or (len(str(<embedded_archive>)) % 2 == 1 and len(str(<nested_pad>)) == 1));
<nested_size_field> ::= <size_field>;
<nested_pad> ::= <member_pad>;
<embedded_archive> ::= <archive_magic> <embedded_member>;
<embedded_member> ::= (
    b'inner.o/        ' <date_field> <uid_field> <gid_field> <mode_field>
    <embedded_size_field> <header_trailer> <embedded_data> <embedded_pad>
)
where int(str(<embedded_size_field>)) == len(str(<embedded_data>))
where ((len(str(<embedded_data>)) % 2 == 0 and len(str(<embedded_pad>)) == 0)
    or (len(str(<embedded_data>)) % 2 == 1 and len(str(<embedded_pad>)) == 1));
<embedded_size_field> ::= <size_field>;
<embedded_data> ::= <member_data>;
<embedded_pad> ::= <member_pad>;
