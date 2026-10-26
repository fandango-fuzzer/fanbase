"""Ask The Unarchiver about a file: exit 0 if lsar tests every entry of it as an archive of the file's format, else say
why and exit 1.

lsar opens a file as whatever archive it finds in it, and says which on its first line: that has to be the format the
file's extension names. It then lists every entry with what testing it gave ("OK.", "Checksum failed!"), on standard
output: the first that failed, or what it said about the archive, is printed. The library it is built on writes its
own warnings into the same lines (a date that does not exist), which are dropped. It tests only formats with checksums
(not tar, cpio, ar or cab, whose entries it calls "Unknown"), so it judges only those.
"""

import os
import re
import signal
import subprocess
import sys

FORMATS = {"7z": {"7-zip"}, "arj": {"arj"}, "rar": {"rar", "rar 5"}, "zip": {"zip"}}
WARNING = re.compile(r"\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+ lsar\[\d+:\d+\] .*$")  # GNUstep's own log lines

path = sys.argv[1]
done = subprocess.run(["lsar", "-t", path], capture_output=True, text=True, errors="replace")
if done.returncode < 0:  # lsar itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
said = []
opened = None
for line in (done.stdout + "\n" + done.stderr).splitlines():
    line = WARNING.sub("", line).strip()
    if line.startswith(path + ":"):
        line = line[len(path) + 1:].strip()
    if not line:
        continue
    if opened is None and not re.search(r"[.!]$|\.\.\. ", line):  # the name of the format it found
        opened = line
    elif re.search(r"(failed|Unsupported)!|Couldn't|parsing failed|requires a password", line):
        said.append(re.sub(r"^.*?\.\.\. ", "", line))
wanted = FORMATS.get(os.path.splitext(path)[1].lstrip(".").lower())
if done.returncode != 0 or said:
    print("\n".join(said) or f"lsar exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
if wanted and (opened is None or opened.lower() not in wanted):
    print(f"read as {opened or 'nothing'}, not as {'/'.join(sorted(wanted))}", file=sys.stderr)
    sys.exit(1)
