"""Ask mpg123 about a file: exit 0 if it decodes audio from it, else say why and exit 1.

mpg123 exits 0 whatever it reads, even a file with no MPEG frame in it: it looks for the next frame and stops at the end.
So the audio it writes is counted, and a file that gives none is rejected with what mpg123 said about it.
"""

import os
import signal
import subprocess
import sys

done = subprocess.run(["mpg123", "--quiet", "--stdout", sys.argv[1]], capture_output=True)
said = done.stderr.decode(errors="replace").strip()
if done.returncode < 0:  # mpg123 itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0 or not done.stdout:
    print(said or "no audio decoded", file=sys.stderr)
    sys.exit(1)
