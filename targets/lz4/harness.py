"""Ask the lz4 tool about a file: exit 0 if `lz4 -t` decodes every frame of it (LZ4 frames, legacy frames, skippable
frames) and checks the checksums it has, else say why and exit 1.

lz4 names the file in what it says, and the name is left out, so that the same reason is counted as one.
"""

import os
import re
import signal
import subprocess
import sys

if sys.argv[1:] == ["--version"]:
    said = subprocess.run(["lz4", "--version"], capture_output=True, text=True, errors="replace", stdin=subprocess.DEVNULL)
    found = re.search(r"v(\d[\d.]*)", said.stdout + said.stderr)
    print(found.group(1) if found else "unknown")
    sys.exit(0)

path = sys.argv[1]
done = subprocess.run(["lz4", "-t", path], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
if done.returncode < 0:  # lz4 itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = done.stderr.decode(errors="replace").replace(path, "FILE").strip()
    print(said or f"lz4 exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
