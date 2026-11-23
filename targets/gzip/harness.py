"""Ask GNU gzip about a file: exit 0 if `gzip -t` decompresses every member of it (and checks its CRC-32 and size), else
say why and exit 1.

gzip also reads the files of Unix compress (.Z). It names the file in what it says, and the name is left out, so that the
same reason is counted as one. A warning (exit status 2, as for data after the last member) is a rejection.
"""

import os
import signal
import subprocess
import sys

path = sys.argv[1]
done = subprocess.run(["gzip", "-t", path], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
if done.returncode < 0:  # gzip itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = done.stderr.decode(errors="replace").replace(path, "FILE").strip()
    print(said or f"gzip exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
