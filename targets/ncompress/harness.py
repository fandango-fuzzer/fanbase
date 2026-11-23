"""Ask ncompress about a file: exit 0 if `compress -d` decompresses it from its standard input, else say why and exit 1.

ncompress is the compress of the Unix tradition, kept up to date. Its own `compress -d` is run, since `uncompress` is gzip's
on Debian and Ubuntu. The decompressed data goes to nothing.
"""

import os
import re
import signal
import subprocess
import sys

if sys.argv[1:] == ["--version"]:
    said = subprocess.run(["compress", "-V"], capture_output=True, text=True, errors="replace", stdin=subprocess.DEVNULL)
    found = re.search(r"compress (\d[\d.]*)", said.stdout + said.stderr)
    print(found.group(1) if found else "unknown")
    sys.exit(0)

path = sys.argv[1]
with open(path, "rb") as data:
    done = subprocess.run(["compress", "-d", "-c"], stdin=data, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
if done.returncode < 0:  # compress itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = done.stderr.decode(errors="replace").replace(path, "FILE").strip()
    print(said or f"compress exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
