"""Ask FAAD2 about a file: exit 0 if it decodes all of it, else say why and exit 1.

faad exits 0 even when it cannot decode a file: it prints "Error: ..." and stops. So that line is the verdict. Its banner
(name, build date, licence) is about the machine and not about the file, and is dropped.
"""

import os
import re
import signal
import subprocess
import sys

if sys.argv[1:] == ["--version"]:
    banner = subprocess.run(["faad", "-h"], capture_output=True, text=True, errors="replace")
    found = re.search(r"Decoder V(\S+)", banner.stdout + banner.stderr)
    print(found.group(1) if found else "unknown")
    sys.exit(0)

done = subprocess.run(["faad", "-w", sys.argv[1]], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
said = done.stderr.decode(errors="replace")
if done.returncode < 0:  # faad itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
errors = [line.strip() for line in said.splitlines() if line.strip().startswith("Error")]
if done.returncode != 0 or errors:
    print("\n".join(errors) or said.strip()[-500:], file=sys.stderr)
    sys.exit(1)
