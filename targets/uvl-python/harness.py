"""Ask uvl-parser's Python parser about a file: exit 0 if `get_tree` parses it, else say why and exit 1.

`get_tree` (in uvl-parser's `python/main.py`) is what the package gives its users: it reads the file and
parses a feature model, raising on a syntax error. The uvlparser package from PyPI installs it as the
module `main`. If UVL_PARSER_ROOT names a checkout of uvl-parser whose Python parser has been generated
(`make python_parser`), that checkout is asked instead: this is how the project fuzzes its own parser.
"""

import os
import sys

root = os.environ.get("UVL_PARSER_ROOT")
if root:
    sys.path.insert(0, os.path.join(root, "python"))

if sys.argv[1:] == ["--version"]:  # which parser is asked: the checkout, or the package
    if root:
        print(f"checkout {os.path.basename(os.path.normpath(root))}")
    else:
        from importlib.metadata import version
        print(version("uvlparser"))
    sys.exit(0)

sys.setrecursionlimit(10_000)

from main import get_tree  # noqa: E402

try:
    get_tree(sys.argv[1])
except RecursionError:
    print("RecursionError: nesting too deep", file=sys.stderr)
    sys.exit(1)
except Exception as exc:  # whatever the parser raises is a rejection
    message = " ".join(str(exc).split())
    print(f"{type(exc).__name__}: {message}", file=sys.stderr)
    sys.exit(1)
