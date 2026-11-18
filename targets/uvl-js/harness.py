"""Ask uvl-parser's JavaScript parser about a file: exit 0 if `new FeatureModel(file)` parses it.

The parser comes from a checkout of uvl-parser with `make js_parser` and `npm install` done in js/:
set UVL_PARSER_ROOT to it. UVL_JS_RUNTIME=deno runs it with Deno instead of Node.
"""

import os
import subprocess
import sys
from pathlib import Path

root = os.environ.get("UVL_PARSER_ROOT")
if not root:
    print("UVL_PARSER_ROOT is not set: it names the uvl-parser checkout whose JavaScript parser is asked",
          file=sys.stderr)
    sys.exit(127)

script = str(Path(__file__).resolve().parent / "harness.mjs")
file = os.path.abspath(sys.argv[1])
if os.environ.get("UVL_JS_RUNTIME") == "deno":
    # Deno finds the package's node_modules from where it runs, not from the files it imports
    command = ["deno", "run", "--allow-read", "--allow-env", "--node-modules-dir=manual",
               "--v8-flags=--stack-size=8000", script, file]
else:
    command = ["node", "--stack-size=8000", script, file]
done = subprocess.run(command, capture_output=True, text=True, stdin=subprocess.DEVNULL,
                      cwd=os.path.join(root, "js"))
sys.stderr.write(done.stderr)
sys.exit(done.returncode)
