"""Ask the zstd tool about a file: exit 0 if `zstd -t` decodes every frame of it and checks the checksums it has, else say
why and exit 1.

zstd allows a window of up to 128 MiB, and a frame that asks for more is refused ("Frame requires too much memory"),
as is one that needs a dictionary. It names the file in what it says, and the name is left out, so that the same reason
is counted as one.
"""

import os
import re
import signal
import subprocess
import sys

if sys.argv[1:] == ["--version"]:
    said = subprocess.run(["zstd", "--version"], capture_output=True, text=True, errors="replace", stdin=subprocess.DEVNULL)
    found = re.search(r"v(\d[\d.]*)", said.stdout + said.stderr)
    print(found.group(1) if found else "unknown")
    sys.exit(0)

path = sys.argv[1]
done = subprocess.run(["zstd", "-t", "-q", path], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
if done.returncode < 0:  # zstd itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = done.stderr.decode(errors="replace").replace(path, "FILE").strip()
    print(said or f"zstd exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
