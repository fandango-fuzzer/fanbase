# PNG, always 32x32 8-bit RGB, with optional tEXt chunks and a real zlib
# stream in IDAT. Lengths and CRCs are set with where constraints instead of
# helper functions.
#
# TODO:
# * Consider replacingc constructor functions with grammar rules + constraints
# * Try not to depend on `random`; let Fandango do this

import struct
import zlib
import binascii
import random

IMAGE_WIDTH: int = 32
IMAGE_HEIGHT: int = 32
TEXT_LENGTH: int = 100

<start> ::= \
    <png_signature> \
    <ihdr_chunk> \
    <text_chunk>* \
    <idat_chunk>+ \
    <iend_chunk>

<png_signature> ::= b"\x89PNG\r\n\x1a\n"

<ihdr_chunk> ::= \
    <ihdr_length> \
    <ihdr_type> \
    <ihdr_data> \
    <ihdr_crc>

<ihdr_length> ::= <byte>{4}
where <ihdr_length> == int_to_be_bytes(13)

<ihdr_type> ::= b"IHDR"

<ihdr_data> ::= \
    <ihdr_width> \
    <ihdr_height> \
    <ihdr_bit_depth> \
    <ihdr_color_type> \
    <ihdr_compression> \
    <ihdr_filter> \
    <ihdr_interlace>

<ihdr_width> ::= <byte>{4} := int_to_be_bytes(IMAGE_WIDTH)

<ihdr_height> ::= <byte>{4} := int_to_be_bytes(IMAGE_HEIGHT)

<ihdr_bit_depth> ::= b"\x08"

<ihdr_color_type> ::= b"\x02"

<ihdr_compression> ::= b"\x00"

<ihdr_filter> ::= b"\x00"

<ihdr_interlace> ::= b"\x00"

<ihdr_crc> ::= <byte>{4}
where <ihdr_crc> == crc32_bytes( \
    bytes(<ihdr_type>) + bytes(<ihdr_data>) \
)

<text_chunk> ::= \
    <text_length> \
    <text_type> \
    <text_data> \
    <text_crc>

<text_length> ::= <byte>{4}
where <text_length> == int_to_be_bytes(len(bytes(<text_data>)))

<text_type> ::= b"tEXt"

<text_data> ::= <byte>{TEXT_LENGTH} := generate_ascii_text(TEXT_LENGTH)

<text_crc> ::= <byte>{4}
where <text_crc> == crc32_bytes( \
    bytes(<text_type>) + bytes(<text_data>) \
)

<idat_chunk> ::= \
    <idat_length> \
    <idat_type> \
    <idat_data> \
    <idat_crc>

<idat_length> ::= <byte>{4}
where <idat_length> == int_to_be_bytes(len(bytes(<idat_data>)))

<idat_type> ::= b"IDAT"

<idat_data> ::= <byte>* := generate_idat_data(IMAGE_WIDTH, IMAGE_HEIGHT)

<idat_crc> ::= <byte>{4}
where <idat_crc> == crc32_bytes( \
    bytes(<idat_type>) + bytes(<idat_data>) \
)

<iend_chunk> ::= \
    <iend_length> \
    <iend_type> \
    <iend_crc>

<iend_length> ::= <byte>{4}
where <iend_length> == int_to_be_bytes(0)

<iend_type> ::= b"IEND"

<iend_crc> ::= <byte>{4}
where <iend_crc> == crc32_bytes(bytes(<iend_type>))

# Helper Functions

def int_to_be_bytes(value: int) -> bytes:
    """
    Convert integer to 4-byte big-endian format.

    :param value: Integer value.
    :return: 4-byte big-endian byte sequence.
    """
    return struct.pack(">I", value)

def crc32_bytes(data: bytes) -> bytes:
    """
    Compute PNG CRC32 checksum.

    :param data: Input bytes.
    :return: 4-byte big-endian CRC.
    """
    crc: int = binascii.crc32(bytes(data)) & 0xffffffff
    return struct.pack(">I", crc)

def generate_ascii_text(length: int) -> bytes:
    """
    Generate ASCII text of fixed length.

    :param length: Number of characters.
    :return: ASCII byte string.
    """
    return bytes(
        random.randint(32, 126)
        for _ in range(length)
    )

def generate_idat_data(width: int, height: int) -> bytes:
    """
    Generate valid PNG scanlines and compress them.

    For each scanline:
      - 1 filter byte (0)
      - width * 3 RGB bytes

    The concatenated raw data is zlib-compressed.

    :param width: Image width.
    :param height: Image height.
    :return: zlib-compressed image data.
    """
    raw: bytearray = bytearray()

    for _ in range(height):
        raw.append(0)
        for _ in range(width * 3):
            raw.append(random.getrandbits(8))

    return zlib.compress(bytes(raw))
