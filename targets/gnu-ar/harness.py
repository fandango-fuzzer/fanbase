"""Ask GNU ar about a file: exit 0 if it reads out every member of it, else say why and exit 1.

`ar p` writes the members to its standard output, which goes to nothing here: reading them out is what finds an
archive that ends inside a member, which listing them (`ar t`) does not.
"""

import os
import signal
import subprocess
import sys

done = subprocess.run(["ar", "p", sys.argv[1]], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
if done.returncode < 0:  # ar itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = done.stderr.decode(errors="replace").strip().replace(sys.argv[1], "<file>")
    print(said or f"ar exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
