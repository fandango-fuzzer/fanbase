"""Ask YAJL about a file: exit 0 if json_verify reads it as JSON, else say why and exit 1.

json_verify reads its standard input, and after the reason it prints the text around the error and an arrow: only the
reason is kept.
"""

import os
import signal
import subprocess
import sys

if sys.argv[1:] == ["--version"]:  # json_verify does not say which version it is; its package does
    asked = subprocess.run(["dpkg-query", "-W", "-f=${Version}", "yajl-tools"], capture_output=True, text=True)
    print(asked.stdout.strip() or "unknown")
    sys.exit(0)

with open(sys.argv[1], "rb") as data:
    done = subprocess.run(["json_verify"], stdin=data, capture_output=True, text=True, errors="replace")
if done.returncode < 0:  # json_verify itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = [line.strip() for line in (done.stderr + "\n" + done.stdout).splitlines() if line.strip()]
    print(said[0] if said else f"json_verify exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
