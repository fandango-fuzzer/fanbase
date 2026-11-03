"""Ask jq about a file: exit 0 if jq reads it as exactly one JSON value, else say why and exit 1.

jq reads a stream of values, so an empty file or two values one after the other are fine to it; a JSON document is one
value, so the values are counted (-s, then length) and the file is accepted only if there is one. jq also takes NaN
and Infinity; that is left to it. Where in the file the error is ("at line 1, column 9") is left out of the reason.
"""

import os
import re
import signal
import subprocess
import sys

done = subprocess.run(["jq", "-c", "-s", "length", sys.argv[1]], capture_output=True, text=True, errors="replace")
if done.returncode < 0:  # jq itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = re.sub(r" at line \d+, column \d+", "", done.stderr.strip())
    print(said or f"jq exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
if done.stdout.strip() != "1":
    print(f"{done.stdout.strip() or 'no'} values, not one", file=sys.stderr)
    sys.exit(1)
