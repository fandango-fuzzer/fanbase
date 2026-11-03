"""Ask libxml2 about a file: exit 0 if xmllint reads it as well-formed XML, else say why and exit 1.

xmllint is told not to fetch anything from the network (--nonet) and not to substitute entities, so a document is read
as it is. Its messages start with the file's name and a line number, and name the elements and entities they are about;
those are dropped, so that the same reason is counted as one.
"""

import os
import re
import signal
import subprocess
import sys

done = subprocess.run(["xmllint", "--noout", "--nonet", sys.argv[1]], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
                      text=True, errors="replace")
if done.returncode < 0:  # xmllint itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = [found.group(1) for found in re.finditer(r"(?:parser|namespace|validity) (?:error|warning) : (.*)", done.stderr)]
    said = [re.sub(r"'[^']*'|\"[^\"]*\"", "X", line) for line in said]
    said = [re.sub(r"mismatch: \S+ line \d+ and \S+", "mismatch", line) for line in said]
    print("\n".join(said) or done.stderr.strip()[-300:] or f"xmllint exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
