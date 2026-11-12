"""Ask the WOFF reference code about a font: exit 0 if woff2sfnt makes it back into an sfnt, else say why and exit 1.

woff2sfnt (woff-tools) is the code that came with the WOFF 1.0 specification; it checks the header, the directory and
the blocks, and decompresses every table. It writes the font to its output, which is thrown away.
"""

import os
import signal
import subprocess
import sys

done = subprocess.run(["woff2sfnt", sys.argv[1]], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True,
                      errors="replace")
if done.returncode < 0:  # woff2sfnt itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    print(done.stderr.replace("###", "").strip() or f"woff2sfnt exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
