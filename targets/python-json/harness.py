"""Ask Python's json about a file: exit 0 if json.load reads it, else say why and exit 1.

The file is read as UTF-8 (RFC 8259 says JSON is), and its bytes must be that. json.load is used with its defaults, as
an application would: it also takes NaN and Infinity, and repeated keys. Whatever it raises is a rejection.
"""

import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8", errors="strict") as text:
        json.load(text)
except Exception as exc:  # whatever json raises is a rejection
    message = str(exc).split(": line ")[0]  # "Expecting value: line 1 column 5 (char 4)": where is not why
    print(f"{type(exc).__name__}: {message}", file=sys.stderr)
    sys.exit(1)
