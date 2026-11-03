"""Ask cbor2 about a file: exit 0 if it decodes it as one CBOR data item, else say why and exit 1.

A .cbor file holds one data item, so whatever comes after it is an error too. cbor2 turns the tags it knows into Python
values (a date-time string into a datetime, a bignum into an int, a UUID, a regular expression, an IP address) and
rejects one whose content does not make sense for its tag: it judges validity, not only well-formedness. Whatever it
raises is a rejection.
"""

import io
import sys

import cbor2

try:
    with open(sys.argv[1], "rb") as data:
        whole = data.read()
    stream = io.BytesIO(whole)
    cbor2.load(stream)
    if stream.tell() != len(whole):
        print(f"data after the item ({len(whole) - stream.tell()} bytes)", file=sys.stderr)
        sys.exit(1)
except Exception as exc:  # whatever cbor2 raises is a rejection
    print(f"{type(exc).__name__}: {str(exc).splitlines()[0] if str(exc) else ''}", file=sys.stderr)
    sys.exit(1)
