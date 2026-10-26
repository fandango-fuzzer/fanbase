"""Ask libarchive about a file: exit 0 if bsdtar reads every entry of it, contents and all, else say why and exit 1.

bsdtar reads the contents of every entry when it writes them to its standard output (-x -O), and that is when the
checksums of the formats that have them are checked (CRC-32 of ZIP, 7z and RAR, those of CAB): the contents go to nothing
here. Its messages start with the name of the entry and may end with an errno that is not about them, and those are
dropped, as are the checksums in them, so that the same reason is counted as one.
"""

import os
import re
import signal
import subprocess
import sys

done = subprocess.run(["bsdtar", "-x", "-O", "-f", sys.argv[1]], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
if done.returncode < 0:  # bsdtar itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = [line.strip() for line in done.stderr.decode(errors="replace").splitlines() if line.strip()]
    said = [line for line in said if line != "bsdtar: Error exit delayed from previous errors."]
    said = [re.sub(r"^bsdtar: ", "", line) for line in said]
    said = [re.sub(r"^[^\s:]+: ", "", line, count=1) for line in said]
    # what bsdtar adds of errno after libarchive's message is left over from elsewhere, and checksums differ from file to file
    said = [re.sub(r": (Unknown error -?\d+|Invalid or incomplete multibyte or wide character|Success)$", "", line) for line in said]
    said = [re.sub(r"\b(?=[0-9a-f]*[0-9])[0-9a-f]{4,16}\b", "N", line) for line in said]
    print("\n".join(said) or f"bsdtar exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
