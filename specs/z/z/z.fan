# Files of Unix compress (.Z): the magic number, the flags byte (the largest
# code width, 9 to 16 bits, and block mode, in which code 256 clears the
# dictionary) and the LZW codes, packed from the lowest bit up in groups of
# eight codes of one width. An encoder here compresses data drawn with
# `random`: none, one byte, distinct bytes (literal codes only), one byte
# repeated (codes from the dictionary, the code just being defined among
# them), random data with CLEAR codes, and random data that takes the code
# width from 9 up to 11 bits. A decoder here checks every stream against its
# header in a where constraint.
#
# TODO:
# * The data is drawn with `random`, not by Fandango.
# * No codes wider than 11 bits: that takes some 2,000 new codes, and more
#   data than these streams hold.

import random


# Writes codes in groups of eight of one width, as compress does.
class _ZPacker:
    def __init__(self):
        self.output = bytearray()
        self.width = 9
        self.value = 0
        self.bits = 0
        self.codes = 0

    def put(self, code):
        self.value |= code << self.bits
        self.bits += self.width
        self.codes += 1
        if self.codes == 8:
            self.output.extend(self.value.to_bytes(self.width, "little"))
            self.value = 0
            self.bits = 0
            self.codes = 0

    def align_width_group(self):
        if self.codes:
            self.output.extend(self.value.to_bytes(self.width, "little"))
        self.value = 0
        self.bits = 0
        self.codes = 0

    def change_width(self, width):
        self.align_width_group()
        self.width = width

    def finish(self):
        if self.codes:
            self.output.extend(self.value.to_bytes((self.bits + 7) // 8, "little"))
        return bytes(self.output)


# The LZW codes of the data, packed: the code width grows when the next
# free code no longer fits, up to maxbits; in block mode a CLEAR code every
# clear_interval new codes resets the dictionary.
def encode_lzw(source, maxbits, block_mode, clear_interval):
    if not source:
        return b""
    limit = 1 << maxbits
    clear_code = 256
    first_free = 257 if block_mode else 256
    table = dict()
    next_code = first_free
    max_code = (1 << 9) - 1
    packer = _ZPacker()
    misses = 0

    def emit(code):
        nonlocal max_code
        if next_code > max_code and packer.width < maxbits:
            packer.change_width(packer.width + 1)
            max_code = (1 << packer.width) - 1
        packer.put(code)

    phrase = bytes([source[0]])
    for octet in source[1:]:
        char = bytes([octet])
        extended = phrase + char
        if len(extended) > 1 and extended in table:
            phrase = extended
            continue
        emit(phrase[0] if len(phrase) == 1 else table[phrase])
        if next_code < limit:
            table = dict(list(table.items()) + [(extended, next_code)])
            next_code += 1
        misses += 1
        if block_mode and clear_interval and misses % clear_interval == 0:
            emit(clear_code)
            packer.align_width_group()
            packer.width = 9
            table = dict()
            next_code = first_free
            max_code = (1 << 9) - 1
        phrase = char
    emit(phrase[0] if len(phrase) == 1 else table[phrase])
    return packer.finish()


# Reads them back.
class _ZReader:
    def __init__(self, payload):
        self.payload = payload
        self.offset = 0
        self.width = 9
        self.group = b""
        self.group_value = 0
        self.index = 8

    def _load_group(self):
        remaining = len(self.payload) - self.offset
        if remaining <= 0:
            return False
        take = min(self.width, remaining)
        self.group = self.payload[self.offset:self.offset + take]
        self.group_value = int.from_bytes(self.group, "little")
        self.offset += take
        self.index = 0
        return True

    def get(self):
        if self.index == 8 and not self._load_group():
            return None
        bit = self.index * self.width
        if bit + self.width > len(self.group) * 8:
            return None
        code = (self.group_value >> bit) & ((1 << self.width) - 1)
        self.index += 1
        return code

    def align(self):
        if self.index < 8:
            used = min(self.index * self.width, len(self.group) * 8)
            if self.group_value >> used:
                return False
        self.index = 8
        return True

    def change_width(self, width):
        if not self.align():
            return False
        self.width = width
        return True

    def clean_eof(self):
        if self.offset != len(self.payload):
            return False
        if self.index == 8:
            return True
        used = min(self.index * self.width, len(self.group) * 8)
        return (self.group_value >> used) == 0


# Whether a decoder takes the codes: every code is a literal, a code in the
# dictionary or the next one to be defined; the widths and CLEAR codes are
# where the header says, and the padding bits are zero.
def valid_lzw(payload, maxbits, block_mode):
    if not (9 <= maxbits <= 16):
        return False
    if not payload:
        return True
    clear_code = 256
    first_free = 257 if block_mode else 256
    limit = 1 << maxbits
    reader = _ZReader(payload)
    dictionary = dict()
    next_code = first_free
    max_code = (1 << 9) - 1
    previous = None
    saw_code = False

    while True:
        if previous is not None and next_code > max_code and reader.width < maxbits:
            if not reader.change_width(reader.width + 1):
                return False
            max_code = (1 << reader.width) - 1
        code = reader.get()
        if code is None:
            return saw_code and reader.clean_eof()
        saw_code = True
        if block_mode and code == clear_code:
            if not reader.align():
                return False
            reader.width = 9
            dictionary = dict()
            next_code = first_free
            max_code = (1 << 9) - 1
            previous = None
            continue
        if previous is None:
            if code > 255:
                return False
            previous = bytes([code])
            continue
        if code < 256:
            entry = bytes([code])
        elif code in dictionary:
            entry = dictionary[code]
        elif code == next_code:
            entry = previous + previous[:1]
        else:
            return False
        if next_code < limit:
            dictionary = dict(list(dictionary.items()) + [(next_code, previous + entry[:1])])
            next_code += 1
        previous = entry


<start> ::= <z_file>

<z_file> ::= <block_mode_file> | <nonblock_mode_file> | <adaptive_width_file>

<block_mode_file> ::= <magic> <block_flags> <packed_block_code_stream>
where bytes(<magic>) == b"\x1f\x9d" and len(bytes(<block_flags>)) == 1 and (bytes(<block_flags>)[0] & 0x80) == 0x80 and (bytes(<block_flags>)[0] & 0x60) == 0 and 9 <= (bytes(<block_flags>)[0] & 0x1f) <= 16 and valid_lzw(bytes(<packed_block_code_stream>), bytes(<block_flags>)[0] & 0x1f, True)

<nonblock_mode_file> ::= <magic> <nonblock_flags> <packed_nonblock_code_stream>
where bytes(<magic>) == b"\x1f\x9d" and len(bytes(<nonblock_flags>)) == 1 and (bytes(<nonblock_flags>)[0] & 0x80) == 0 and (bytes(<nonblock_flags>)[0] & 0x60) == 0 and 9 <= (bytes(<nonblock_flags>)[0] & 0x1f) <= 16 and valid_lzw(bytes(<packed_nonblock_code_stream>), bytes(<nonblock_flags>)[0] & 0x1f, False)

# Up to 16-bit codes, and data enough to need wider ones
<adaptive_width_file> ::= <magic> <adaptive_flags> <adaptive_width_stream>
where bytes(<magic>) == b"\x1f\x9d" and len(bytes(<adaptive_flags>)) == 1 and (bytes(<adaptive_flags>)[0] & 0x80) == 0x80 and (bytes(<adaptive_flags>)[0] & 0x60) == 0 and (bytes(<adaptive_flags>)[0] & 0x1f) == 16 and valid_lzw(bytes(<adaptive_width_stream>), bytes(<adaptive_flags>)[0] & 0x1f, True)

<magic> ::= b"\x1f\x9d"

# The sixteen flags bytes: 9 to 16 bits, with or without block mode
<block_flags> ::= br'[\x89-\x90]'
<nonblock_flags> ::= br'[\x09-\x10]'
<adaptive_flags> ::= b"\x90"

<packed_block_code_stream> ::= <empty_code_stream> | <initial_literal_code_stream> | <later_literal_code_stream> | <block_dictionary_code_stream> | <clear_code_stream>
<packed_nonblock_code_stream> ::= <empty_code_stream> | <initial_literal_code_stream> | <later_literal_code_stream> | <nonblock_dictionary_code_stream>

# No codes at all: no data
<empty_code_stream> ::= b""

# One byte: a single literal code
<initial_literal_code_stream> ::= br'[\x00-\xff]*' := encode_lzw(random.randbytes(1), 9, False, 0)

# 2 to 12 distinct bytes: literal codes only
<later_literal_code_stream> ::= br'[\x00-\xff]*' := encode_lzw(bytes(random.sample(range(256), random.randint(2, 12))), 9, False, 0)

# One byte 24 to 240 times: codes from the dictionary, and the code that is
# being defined (the "KwKwK" case)
<block_dictionary_code_stream> ::= br'[\x00-\xff]*' := encode_lzw(bytes([random.randrange(256)]) * random.randint(24, 240), 9, True, 0)
<nonblock_dictionary_code_stream> ::= br'[\x00-\xff]*' := encode_lzw(bytes([random.randrange(256)]) * random.randint(24, 240), 9, False, 0)

# Random data with a CLEAR code (256, block mode only) every 32 to 64 new
# codes: the dictionary starts again, from code 257 and 9 bits
<clear_code_stream> ::= br'[\x00-\xff]*' := encode_lzw(random.randbytes(random.randint(260, 420)), 9, True, random.randint(32, 64))

# 1,500 to 2,200 random bytes: codes of 9, 10 and 11 bits
<adaptive_width_stream> ::= br'[\x00-\xff]*' := encode_lzw(random.randbytes(random.randint(1500, 2200)), 16, True, 0)
