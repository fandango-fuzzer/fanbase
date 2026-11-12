"""Ask the OpenType Sanitizer about a font: exit 0 if ots-sanitize passes it, else say why and exit 1.

OTS is what Chrome and Firefox check a web font with before they use it; it reads TrueType and OpenType fonts, WOFF and
WOFF2, and refuses a font when a table it needs is broken (it drops or fixes others, and warns). It prints its warnings
before its errors, and fanbase reads the first line: the errors are printed first here, and nothing else is changed.
"""

import os
import signal
import subprocess
import sys

done = subprocess.run(["ots-sanitize", sys.argv[1]], capture_output=True, text=True, errors="replace")
if done.returncode < 0:  # ots-sanitize itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    lines = [line for line in done.stderr.splitlines() if line.strip()]
    errors = [line for line in lines if line.startswith("ERROR")]
    print("\n".join(errors + [line for line in lines if line not in errors])
          or done.stdout.strip() or f"ots-sanitize exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
