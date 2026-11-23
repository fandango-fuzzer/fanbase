"""Ask plzip about a file: exit 0 if `plzip -t` decompresses every member of it and checks its CRC-32 and sizes, else say
why and exit 1.

plzip decompresses with lzlib, a library apart from lzip's own decoder. It names the file in what it says, and the name
is left out, so that the same reason is counted as one.
"""

import os
import signal
import subprocess
import sys

path = sys.argv[1]
done = subprocess.run(["plzip", "-t", path], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
if done.returncode < 0:  # plzip itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = done.stderr.decode(errors="replace").replace(path, "FILE").strip()
    print(said or f"plzip exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
