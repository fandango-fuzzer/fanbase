"""Ask BusyBox about a file: exit 0 if its decompressor for the file's format reads all of it, else say why and exit 1.

BusyBox has decompressors of its own, not those of gzip, bzip2 or XZ Utils (unxz is XZ Embedded): gunzip, bunzip2, unxz
and uncompress, by the file's extension, each writing what it decompresses to nothing (-c).
"""

import os
import signal
import subprocess
import sys

APPLETS = {"gz": "gunzip", "bz2": "bunzip2", "xz": "unxz", "z": "uncompress"}

if sys.argv[1:] == ["--version"]:
    banner = subprocess.run(["busybox"], capture_output=True, text=True, errors="replace").stdout.split()
    print(banner[1].lstrip("v") if len(banner) > 1 else "unknown")
    sys.exit(0)

path = sys.argv[1]
applet = APPLETS[os.path.splitext(path)[1].lstrip(".").lower()]
with open(path, "rb") as data:
    done = subprocess.run(["busybox", applet, "-c"], stdin=data, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
if done.returncode < 0:  # BusyBox itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = done.stderr.decode(errors="replace").strip()
    print(said or f"busybox {applet} exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
