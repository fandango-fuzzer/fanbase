"""Ask Google's WOFF2 library about a font: exit 0 if woff2_decompress makes it back into an sfnt, else say why and exit 1.

woff2_decompress writes the font it makes next to the file it reads, so the file is copied into a folder that is
removed. It says nothing on success and little on failure; what it says is passed on.
"""

import os
import shutil
import signal
import subprocess
import sys
import tempfile

with tempfile.TemporaryDirectory() as folder:
    copy = os.path.join(folder, "font.woff2")
    shutil.copyfile(sys.argv[1], copy)
    done = subprocess.run(["woff2_decompress", copy], capture_output=True, text=True, errors="replace")
if done.returncode < 0:  # woff2_decompress itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    print((done.stderr + done.stdout).replace(copy, "<file>").strip() or "woff2_decompress refused it", file=sys.stderr)
    sys.exit(1)
