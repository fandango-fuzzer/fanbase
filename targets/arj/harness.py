"""Ask ARJ about a file: exit 0 if it tests every file in it, else say why and exit 1.

arj starts with a banner and says which archive and which file it is testing, all on standard output, and the reason
comes last ("CRC error!" at the end of the line of a file, "Can't read file or unexpected end of file" after a
message about errno): the banner and those lines are dropped, and the last thing it said is printed first. An archive
with no file in it is an error to arj. It is told to answer yes to every question (-y), so that it never waits for one.
"""

import os
import re
import signal
import subprocess
import sys

NOISE = re.compile(r"(ARJ\S* v|Processing archive|Archive created|Found\s+\d+ error)")

if sys.argv[1:] == ["--version"]:
    banner = subprocess.run(["arj"], capture_output=True, text=True, errors="replace", stdin=subprocess.DEVNULL).stdout
    found = re.search(r"ARJ\S* v ?(\S+)", banner)
    print(found.group(1).rstrip(",") if found else "unknown")
    sys.exit(0)

done = subprocess.run(["arj", "t", "-y", sys.argv[1]], capture_output=True, text=True, errors="replace",
                      stdin=subprocess.DEVNULL)
if done.returncode < 0:  # arj itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = []
    for line in (done.stdout + "\n" + done.stderr).splitlines():
        line = line.strip()
        if line.startswith("Testing"):  # "Testing name   0% 100%CRC error!": what follows the progress is the reason
            line = re.sub(r"^Testing.*?(\d+%\s*)+", "", line) if "%" in line else ""
            if line == "OK":
                continue
        counted = re.search(r"(\d+) file\(s\)$", line)  # "[archive comment]   N file(s)"
        if counted:
            line = "no file in the archive" if counted.group(1) == "0" else ""
        if not line or NOISE.match(line):
            continue
        said.append(line.replace(sys.argv[1], "<file>"))
    print("\n".join(reversed(said)) or f"arj exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
