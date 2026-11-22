"""Ask lzip about a file: exit 0 if `lzip -t` decompresses every member of it and checks its CRC-32 and sizes, else say
why and exit 1.

Debian and Ubuntu install plzip as `lzip` when it is there, and lzip itself as `lzip.lzip`: that one is run if there is
one. lzip names the file in what it says, and the name is left out, so that the same reason is counted as one.
"""

import os
import re
import shutil
import signal
import subprocess
import sys

LZIP = shutil.which("lzip.lzip") or "lzip"

if sys.argv[1:] == ["--version"]:
    said = subprocess.run([LZIP, "--version"], capture_output=True, text=True, errors="replace", stdin=subprocess.DEVNULL)
    found = re.search(r"lzip (\d[\d.]*)", said.stdout + said.stderr)
    print(found.group(1) if found else "unknown")
    sys.exit(0)

path = sys.argv[1]
done = subprocess.run([LZIP, "-t", path], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
if done.returncode < 0:  # lzip itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = done.stderr.decode(errors="replace").replace(path, "FILE").strip()
    print(said or f"lzip exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
