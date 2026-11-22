"""Ask XZ Utils about a file: exit 0 if `xz -t` decompresses every stream of it and checks every block, else say why and
exit 1.

xz names the file in what it says, and the name is left out, so that the same reason is counted as one. A warning (exit
status 2, as for a check it does not know) is a rejection.
"""

import os
import signal
import subprocess
import sys

path = sys.argv[1]
done = subprocess.run(["xz", "-t", path], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
if done.returncode < 0:  # xz itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = done.stderr.decode(errors="replace").replace(path, "FILE").strip()
    print(said or f"xz exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
