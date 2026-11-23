"""Ask bzip2 about a file: exit 0 if `bzip2 -t` decompresses every stream of it and checks its CRCs, else say why and exit
1.

bzip2 names the file in what it says, and the name is left out, so that the same reason is counted as one.
"""

import os
import re
import signal
import subprocess
import sys

if sys.argv[1:] == ["--version"]:
    said = subprocess.run(["bzip2", "--version"], capture_output=True, text=True, errors="replace", stdin=subprocess.DEVNULL)
    found = re.search(r"Version (\d[\d.]*)", said.stdout + said.stderr)
    print(found.group(1) if found else "unknown")
    sys.exit(0)

path = sys.argv[1]
done = subprocess.run(["bzip2", "-t", path], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
if done.returncode < 0:  # bzip2 itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = done.stderr.decode(errors="replace").replace(path, "FILE").strip()
    print(said or f"bzip2 exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
