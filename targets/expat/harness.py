"""Ask Expat about a file: exit 0 if xmlwf reads it as well-formed XML, else say why and exit 1.

xmlwf says what is wrong as "FILE:LINE:COLUMN: reason", on standard output: the reason is what is printed. It does not
read external entities unless it is told to.
"""

import os
import re
import signal
import subprocess
import sys

done = subprocess.run(["xmlwf", sys.argv[1]], capture_output=True, text=True, errors="replace")
if done.returncode < 0:  # xmlwf itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = [re.sub(r"^.*?:\d+:\d+: ", "", line.strip()) for line in (done.stdout + "\n" + done.stderr).splitlines() if line.strip()]
    print("\n".join(said) or f"xmlwf exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
