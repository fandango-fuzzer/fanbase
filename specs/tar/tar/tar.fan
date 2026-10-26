# POSIX ustar archives: one or more entries, each a 512-byte header and,
# for regular files, up to two 512-byte blocks of contents, then two blocks
# of zeros. The entries are regular and contiguous files, directories, hard
# and symbolic links, character and block devices, and FIFOs. The size field
# of a file is the length of its contents, and every header carries its
# checksum, both as octal text tied to the bytes by where constraints.
#
# TODO:
# * Names are eight characters, with no prefix field, and the mode, owner,
#   group and times are the same in every entry.
# * No pax extended headers or GNU extensions (long names, sparse files).
# * The contents are whole blocks, so the size of a file is always 0, 512 or
#   1024.

<start> ::= <entry>+ <trailer>
<entry> ::= <file_entry> | <dir_entry> | <link_entry> | <dev_entry> | <fifo_entry>

<block>   ::= rb'[\x00-\xff]{512}'
<trailer> ::= rb'\x00{1024}'          # two blocks of zeros end the archive

# A regular file ('0') or a contiguous file ('7'), with up to two blocks of
# contents. Mode 644, uid and gid 0, mtime 0, owner root.
<file_entry> ::= <f_nametext> <f_namepad> <f_const1> <f_sizeoct> b'\x00' <f_mtime> <f_chkoct> b'\x00 ' <f_type> <f_link> <f_const2a> <f_devmaj> <f_devmin> <f_const2b> <f_data>
<f_nametext> ::= r'[a-z0-9._]{8}'
<f_namepad>  ::= rb'\x00{92}'
<f_const1>   ::= b'0000644\x00' b'0000000\x00' b'0000000\x00'
<f_sizeoct>  ::= r'[0-7]{11}'
<f_mtime>    ::= b'00000000000\x00'
<f_chkoct>   ::= r'[0-7]{6}'
<f_type>     ::= b'0' | b'7'
<f_link>     ::= rb'\x00{100}'
<f_const2a>  ::= b'ustar\x00' b'00' b'root' rb'\x00{28}' b'root' rb'\x00{28}'
<f_devmaj>   ::= b'0000000\x00'
<f_devmin>   ::= b'0000000\x00'
<f_const2b>  ::= rb'\x00{167}'
<f_data>     ::= <block>{0,2}

# A directory ('5'): the name ends in '/', and there are no contents
<dir_entry> ::= <d_nametext> <d_namepad> <d_const1> <d_size> <d_mtime> <d_chkoct> b'\x00 ' <d_type> <d_link> <d_const2a> <d_devmaj> <d_devmin> <d_const2b>
<d_nametext> ::= r'[a-z0-9._]{7}/'
<d_namepad>  ::= rb'\x00{92}'
<d_const1>   ::= b'0000755\x00' b'0000000\x00' b'0000000\x00'
<d_size>     ::= b'00000000000\x00'
<d_mtime>    ::= b'00000000000\x00'
<d_chkoct>   ::= r'[0-7]{6}'
<d_type>     ::= b'5'
<d_link>     ::= rb'\x00{100}'
<d_const2a>  ::= b'ustar\x00' b'00' b'root' rb'\x00{28}' b'root' rb'\x00{28}'
<d_devmaj>   ::= b'0000000\x00'
<d_devmin>   ::= b'0000000\x00'
<d_const2b>  ::= rb'\x00{167}'

# A hard link ('1') or a symbolic link ('2') to the path in linkname
<link_entry> ::= <l_nametext> <l_namepad> <l_const1> <l_size> <l_mtime> <l_chkoct> b'\x00 ' <l_type> <l_linktext> <l_linkpad> <l_const2a> <l_devmaj> <l_devmin> <l_const2b>
<l_nametext> ::= r'[a-z0-9._]{8}'
<l_namepad>  ::= rb'\x00{92}'
<l_const1>   ::= b'0000777\x00' b'0000000\x00' b'0000000\x00'
<l_size>     ::= b'00000000000\x00'
<l_mtime>    ::= b'00000000000\x00'
<l_chkoct>   ::= r'[0-7]{6}'
<l_type>     ::= b'1' | b'2'
<l_linktext> ::= r'[a-z0-9._/]{8}'
<l_linkpad>  ::= rb'\x00{92}'
<l_const2a>  ::= b'ustar\x00' b'00' b'root' rb'\x00{28}' b'root' rb'\x00{28}'
<l_devmaj>   ::= b'0000000\x00'
<l_devmin>   ::= b'0000000\x00'
<l_const2b>  ::= rb'\x00{167}'

# A character device ('3') or a block device ('4'), with its device numbers
<dev_entry> ::= <v_nametext> <v_namepad> <v_const1> <v_size> <v_mtime> <v_chkoct> b'\x00 ' <v_type> <v_link> <v_const2a> <v_devmaj> <v_devmin> <v_const2b>
<v_nametext> ::= r'[a-z0-9._]{8}'
<v_namepad>  ::= rb'\x00{92}'
<v_const1>   ::= b'0000644\x00' b'0000000\x00' b'0000000\x00'
<v_size>     ::= b'00000000000\x00'
<v_mtime>    ::= b'00000000000\x00'
<v_chkoct>   ::= r'[0-7]{6}'
<v_type>     ::= b'3' | b'4'
<v_link>     ::= rb'\x00{100}'
<v_const2a>  ::= b'ustar\x00' b'00' b'root' rb'\x00{28}' b'root' rb'\x00{28}'
<v_devmaj>   ::= b'0000004\x00' | b'0000010\x00' | b'0000001\x00'
<v_devmin>   ::= b'0000004\x00' | b'0000010\x00' | b'0000001\x00'
<v_const2b>  ::= rb'\x00{167}'

# A FIFO ('6')
<fifo_entry> ::= <p_nametext> <p_namepad> <p_const1> <p_size> <p_mtime> <p_chkoct> b'\x00 ' <p_type> <p_link> <p_const2a> <p_devmaj> <p_devmin> <p_const2b>
<p_nametext> ::= r'[a-z0-9._]{8}'
<p_namepad>  ::= rb'\x00{92}'
<p_const1>   ::= b'0000644\x00' b'0000000\x00' b'0000000\x00'
<p_size>     ::= b'00000000000\x00'
<p_mtime>    ::= b'00000000000\x00'
<p_chkoct>   ::= r'[0-7]{6}'
<p_type>     ::= b'6'
<p_link>     ::= rb'\x00{100}'
<p_const2a>  ::= b'ustar\x00' b'00' b'root' rb'\x00{28}' b'root' rb'\x00{28}'
<p_devmaj>   ::= b'0000000\x00'
<p_devmin>   ::= b'0000000\x00'
<p_const2b>  ::= rb'\x00{167}'

# The size of a file is the length of its contents, in octal. The checksum is
# the sum of the bytes of the header with the checksum field counted as eight
# spaces (8 * 0x20 = 256), as six octal digits followed by NUL and space.
where forall <e> in <file_entry>: str(<e>.<f_sizeoct>) == format(len(bytes(<e>.<f_data>)), '011o')
where forall <e> in <file_entry>: str(<e>.<f_chkoct>) == format( \
    sum(bytes(<e>.<f_nametext>)) \
    + sum(bytes(<e>.<f_namepad>)) \
    + sum(bytes(<e>.<f_const1>)) \
    + sum(bytes(<e>.<f_sizeoct>)) \
    + sum(bytes(<e>.<f_mtime>)) \
    + sum(bytes(<e>.<f_type>)) \
    + sum(bytes(<e>.<f_link>)) \
    + sum(bytes(<e>.<f_const2a>)) \
    + sum(bytes(<e>.<f_devmaj>)) \
    + sum(bytes(<e>.<f_devmin>)) \
    + sum(bytes(<e>.<f_const2b>)) + 256, '06o')
where forall <e> in <dir_entry>: str(<e>.<d_chkoct>) == format( \
    sum(bytes(<e>.<d_nametext>)) \
    + sum(bytes(<e>.<d_namepad>)) \
    + sum(bytes(<e>.<d_const1>)) \
    + sum(bytes(<e>.<d_size>)) \
    + sum(bytes(<e>.<d_mtime>)) \
    + sum(bytes(<e>.<d_type>)) \
    + sum(bytes(<e>.<d_link>)) \
    + sum(bytes(<e>.<d_const2a>)) \
    + sum(bytes(<e>.<d_devmaj>)) \
    + sum(bytes(<e>.<d_devmin>)) \
    + sum(bytes(<e>.<d_const2b>)) + 256, '06o')
where forall <e> in <link_entry>: str(<e>.<l_chkoct>) == format( \
    sum(bytes(<e>.<l_nametext>)) \
    + sum(bytes(<e>.<l_namepad>)) \
    + sum(bytes(<e>.<l_const1>)) \
    + sum(bytes(<e>.<l_size>)) \
    + sum(bytes(<e>.<l_mtime>)) \
    + sum(bytes(<e>.<l_type>)) \
    + sum(bytes(<e>.<l_linktext>)) \
    + sum(bytes(<e>.<l_linkpad>)) \
    + sum(bytes(<e>.<l_const2a>)) \
    + sum(bytes(<e>.<l_devmaj>)) \
    + sum(bytes(<e>.<l_devmin>)) \
    + sum(bytes(<e>.<l_const2b>)) + 256, '06o')
where forall <e> in <dev_entry>: str(<e>.<v_chkoct>) == format( \
    sum(bytes(<e>.<v_nametext>)) \
    + sum(bytes(<e>.<v_namepad>)) \
    + sum(bytes(<e>.<v_const1>)) \
    + sum(bytes(<e>.<v_size>)) \
    + sum(bytes(<e>.<v_mtime>)) \
    + sum(bytes(<e>.<v_type>)) \
    + sum(bytes(<e>.<v_link>)) \
    + sum(bytes(<e>.<v_const2a>)) \
    + sum(bytes(<e>.<v_devmaj>)) \
    + sum(bytes(<e>.<v_devmin>)) \
    + sum(bytes(<e>.<v_const2b>)) + 256, '06o')
where forall <e> in <fifo_entry>: str(<e>.<p_chkoct>) == format( \
    sum(bytes(<e>.<p_nametext>)) \
    + sum(bytes(<e>.<p_namepad>)) \
    + sum(bytes(<e>.<p_const1>)) \
    + sum(bytes(<e>.<p_size>)) \
    + sum(bytes(<e>.<p_mtime>)) \
    + sum(bytes(<e>.<p_type>)) \
    + sum(bytes(<e>.<p_link>)) \
    + sum(bytes(<e>.<p_const2a>)) \
    + sum(bytes(<e>.<p_devmaj>)) \
    + sum(bytes(<e>.<p_devmin>)) \
    + sum(bytes(<e>.<p_const2b>)) + 256, '06o')
