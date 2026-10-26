# tar archives of one to three entries whose fields sit at the edges of what
# the format allows, or past them: setuid, setgid and sticky modes, the
# largest uid and gid that seven octal digits hold, POSIX, old GNU and V7 (no
# magic) headers side by side, a prefix field and a link name on every entry,
# device numbers on entries that are not devices (the largest, and one that is
# not octal), every typeflag of POSIX and the GNU, Solaris and vendor ones (g,
# x, L, K, S, D, M, N, V, A), and contents of whole blocks, a pax record
# ("mtime=1") that leaves the archive out of block alignment, or a long name
# that no entry follows. The size field and the header checksum of every entry
# are tied to the bytes by where constraints.
#
# TODO:
# * Most files are refused by most readers: that is what the fields are for,
#   and nothing keeps an entry's type and contents in agreement.

# Up to three entries, then the two blocks of zeros
<start> ::= <entry>{1,3} <trailer>

# An entry: the 512-byte header, field by field (each one a child of the
# entry, so that the checksum below can add them up), then the contents
<entry> ::= <nametext> <namepad> <mode> <uid> <gid> \
            <sizeoct> <sizeterm> <mtimeoct> <mtimeterm> \
            <chkoct> <chkterm> <typeflag> \
            <linktext> <linkpad> <magicver> \
            <unametext> <unamepad> <gnametext> <gnamepad> \
            <devmajor> <devminor> <prefixtext> <prefixpad> <hdrpad> \
            <payload>

# name: eight printable bytes and NULs
<nametext>   ::= r'[!-~]{8}'
<namepad>    ::= rb'\x00{92}'

# mode, uid and gid, in octal: setuid, setgid, sticky, all bits, none; the
# largest values
<mode> ::= b'0000644\x00' | b'0004755\x00' | b'0002755\x00' \
         | b'0001777\x00' | b'0007777\x00' | b'0000000\x00'
<uid>  ::= b'0000000\x00' | b'0001750\x00' | b'0177777\x00' | b'7777777\x00'
<gid>  ::= b'0000000\x00' | b'0001750\x00' | b'0177777\x00' | b'7777777\x00'

# size: eleven octal digits and NUL, the length of the contents
<sizeoct>    ::= r'[0-7]{11}'
<sizeterm>   ::= b'\x00'

# mtime: any eleven octal digits
<mtimeoct>   ::= r'[0-7]{11}'
<mtimeterm>  ::= b'\x00'

# chksum: six octal digits, NUL and a space
<chkoct>     ::= r'[0-7]{6}'
<chkterm>    ::= b'\x00 '

# typeflag: POSIX, then GNU, Solaris and vendor extensions
<typeflag> ::= b'0' | b'\x00' | b'1' | b'2' | b'3' | b'4' | b'5' | b'6' | b'7' \
             | b'g' | b'x' | b'L' | b'K' | b'S' | b'D' | b'M' | b'N' | b'V' | b'A'

# linkname, on every entry
<linktext>   ::= r'[!-~]{8}'
<linkpad>    ::= rb'\x00{92}'

# magic and version: POSIX, old GNU, and V7 (none)
<magicver> ::= b'ustar\x0000' | b'ustar  \x00' | b'\x00\x00\x00\x00\x00\x00\x00\x00'

# uname and gname
<unametext>  ::= r'[a-z]{6}'
<unamepad>   ::= rb'\x00{26}'
<gnametext>  ::= r'[a-z]{6}'
<gnamepad>   ::= rb'\x00{26}'

# devmajor and devminor, on every type of entry: 0, 9 (not an octal
# digit), 255 and the largest
<devmajor> ::= b'0000000\x00' | b'0000009\x00' | b'0000377\x00' | b'7777777\x00'
<devminor> ::= b'0000000\x00' | b'0000009\x00' | b'0000377\x00' | b'7777777\x00'

# prefix, then the rest of the header
<prefixtext> ::= r'[!-~]{6}'
<prefixpad>  ::= rb'\x00{149}'

<hdrpad>     ::= rb'\x00{12}'

# The contents: blocks of bytes (directories and FIFOs have them too), a
# pax record that is not a whole block, or a GNU long name
<payload>      ::= <generic_data> | <pax_data> | <gnu_name_data>
<generic_data> ::= <block>{0,2}
<block>        ::= rb'[\x00-\xff]{512}'
<pax_data>     ::= b'11 mtime=1\n'
<gnu_name_data> ::= b'a/deep/nested/path/that/blows/past/one/hundred/bytes/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\x00'

# The end of the archive: two blocks of zeros
<trailer> ::= rb'\x00{1024}'

# The checksum: the sum of the header's bytes, the checksum field counted
# as eight spaces (256). The fields made of NULs add nothing, so they are
# left out of the sum.
where forall <e> in <entry>: str(<e>.<chkoct>) == format( \
    sum( bytes(<e>.<nametext>) + bytes(<e>.<mode>) + bytes(<e>.<uid>) \
       + bytes(<e>.<gid>) + bytes(<e>.<sizeoct>) + bytes(<e>.<mtimeoct>) \
       + bytes(<e>.<typeflag>) + bytes(<e>.<linktext>) + bytes(<e>.<magicver>) \
       + bytes(<e>.<unametext>) + bytes(<e>.<gnametext>) + bytes(<e>.<devmajor>) \
       + bytes(<e>.<devminor>) + bytes(<e>.<prefixtext>) ) + 256, '06o')

# The size field is the length of the contents.
where forall <e> in <entry>: str(<e>.<sizeoct>) == format(len(bytes(<e>.<payload>)), '011o')
