"""Ask pngcheck about a file: the status of pngcheck itself (0 all is well, 1 a warning, 2 and more an error), and what it says.

pngcheck prints a warning on every run when the zlib it runs with is not the one it was built with ("zlib warning: different
version (expected 1.2.13, using 1.3.1)"), which is about the machine and not about the file. It is the first thing on stderr, and
fanbase reads stderr first, so it hid what pngcheck says about the file. It is dropped here; nothing else is changed.
"""

import os
import re
import signal
import subprocess
import sys

VERSION_WARNING = re.compile(r"zlib warning:\s+different version")

done = subprocess.run(["pngcheck", "-q", sys.argv[1]], capture_output=True, text=True, errors="replace")
said = [line for line in (done.stderr + done.stdout).splitlines() if line.strip() and not VERSION_WARNING.match(line)]
if said:
    print("\n".join(said), file=sys.stderr)
if done.returncode < 0:  # pngcheck itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
sys.exit(done.returncode)
