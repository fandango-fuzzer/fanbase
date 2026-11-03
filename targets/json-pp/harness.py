"""Ask Perl's JSON::PP about a file: exit 0 if json_pp reads it as JSON, else say why and exit 1.

json_pp reads its standard input and writes the value out again, which goes to nothing here. Its message says where in
the text the error is, and which line of json_pp died: those are left out of the reason.
"""

import os
import re
import signal
import subprocess
import sys

with open(sys.argv[1], "rb") as data:
    done = subprocess.run(["json_pp"], stdin=data, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True,
                          errors="replace")
if done.returncode < 0:  # json_pp itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = done.stderr.strip().splitlines()[0] if done.stderr.strip() else f"json_pp exited with {done.returncode}"
    said = re.sub(r",? at character offset \d+ \(before .*$", "", said)
    said = re.sub(r" at \S+ line \d+\.?$", "", said)
    print(said, file=sys.stderr)
    sys.exit(1)
