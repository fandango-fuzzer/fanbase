"""Ask UnRAR about a file: exit 0 if it tests every file in it, else say why and exit 1.

unrar says which archive and which file it is testing before it says what is wrong, on standard output: those lines,
and the names of the files in front of a message, are dropped, so that what is printed starts with the reason. It is
told not to ask for a password (-p-).
"""

import os
import re
import signal
import subprocess
import sys

done = subprocess.run(["unrar", "t", "-p-", "-idcdp", sys.argv[1]], capture_output=True, text=True, errors="replace")
if done.returncode < 0:  # unrar itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = []
    for line in (done.stderr + "\n" + done.stdout).splitlines():
        line = line.strip()
        if not line or line.startswith("Testing") or line == "All OK":
            continue
        line = re.sub(r"^\S+\s+- ", "", line).replace(sys.argv[1], "<file>")
        said.append(re.sub(r"(encrypted file|in the file|volume) \S+?(\.?)( |$)", r"\1 X\2\3", line))
    print("\n".join(said) or f"unrar exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
