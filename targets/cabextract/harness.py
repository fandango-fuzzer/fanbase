"""Ask cabextract about a file: exit 0 if it tests every file in it, else say why and exit 1.

cabextract lists every file with what testing it gave ("OK", "failed (checksum error)") on standard output, and what
it says about the cabinet on standard error, both with the names of files: what failed is printed first, without the
names, so that the same reason is counted as one.
"""

import os
import re
import signal
import subprocess
import sys

path = sys.argv[1]
done = subprocess.run(["cabextract", "-t", "-q", path], capture_output=True, text=True, errors="replace")
if done.returncode < 0:  # cabextract itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    failed = [found.group(1) for found in re.finditer(r"\sfailed \(([^)]*)\)", done.stdout)]
    said = []
    for line in done.stderr.splitlines():
        line = line.strip()
        if line.startswith(path + ":"):
            line = line[len(path) + 1:].strip()
        line = re.sub(r"can't find \S.*$", "can't find a cabinet it names", line)
        line = re.sub(r'"[^"]*"', "a file", line)
        if line:
            said.append(line)
    print("\n".join(failed + said) or f"cabextract exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
