"""Ask djxl about a file: exit 0 if libjxl decodes all of it, else say why and exit 1.

djxl needs a file to write the picture to (the flag that says not to came after the version that Ubuntu 24.04 has), so it
writes into a folder that is removed. Its first line says which version it is, which is about the machine and not about the
file, and fanbase reads stderr first: it is dropped here; nothing else is changed.
"""

import os
import signal
import subprocess
import sys
import tempfile

with tempfile.TemporaryDirectory() as folder:
    done = subprocess.run(["djxl", sys.argv[1], os.path.join(folder, "out.png")], capture_output=True, text=True, errors="replace")
said = [line for line in (done.stderr + done.stdout).splitlines() if line.strip() and not line.startswith("JPEG XL decoder v")]
if said:
    print("\n".join(said), file=sys.stderr)
if done.returncode < 0:  # djxl itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
sys.exit(done.returncode)
