"""Ask the cbor-diag crate about a file: exit 0 if it reads it as one well-formed CBOR data item, else say why and exit 1.

The crate (in Rust; its Python package calls it) parses the bytes into diagnostic notation (RFC 8949, section 8). It
checks well-formedness only: what a tag's content means is not its business. Where in the file the error is ("at
offset 12") is left out of the reason. What the crate has not implemented reaches Python as an exception that is not an
Exception, and is a rejection like the others; the crate also writes about it to standard error on its own, which is
not the reason, so its standard error goes to nothing while it reads.
"""

import os
import re
import sys

import cbor_diag

with open(sys.argv[1], "rb") as data:
    whole = data.read()
kept = os.dup(2)
quiet = os.open(os.devnull, os.O_WRONLY)
os.dup2(quiet, 2)
try:
    cbor_diag.cbor2diag(whole)
    failure = None
except BaseException as exc:  # whatever cbor-diag raises is a rejection
    failure = exc
finally:
    os.dup2(kept, 2)
if failure is not None:
    message = re.sub(r"\b\d+\b", "N", str(failure).splitlines()[0] if str(failure) else "")
    print(f"{type(failure).__name__}: {message}" if isinstance(failure, Exception) else message, file=sys.stderr)
    sys.exit(1)
