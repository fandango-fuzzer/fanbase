"""Ask 7-Zip about a file: exit 0 if it tests every entry of it as an archive of the file's format, else say why and exit 1.

The format is the one the file's extension names, and 7-Zip is told to open the file as that (-t), and as nothing else:
left to find out by itself, it first checks fields that its readers do not need (the device numbers of a cpio entry),
and opens a file as whatever archive it finds in it. RAR is two formats to 7-Zip, so the file's signature says which. A
password is given, so that an encrypted entry fails instead of asking for one. 7-Zip says what went wrong in several
places, with the file's and the entry's names: the first error, without them, is what is printed.
"""

import os
import re
import signal
import subprocess
import sys

TYPES = {"7z": "7z", "a": "ar", "ar": "ar", "arj": "arj", "cab": "cab", "cpio": "cpio", "rar": "rar", "tar": "tar", "zip": "zip"}
RAR5 = b"Rar!\x1a\x07\x01\x00"

if sys.argv[1:] == ["--version"]:
    banner = subprocess.run(["7z"], capture_output=True, text=True, errors="replace").stdout
    found = re.search(r"7-Zip (?:\[\d+\] )?(?:\(\w+\) )?(\d\S*)", banner)
    print(found.group(1) if found else "unknown")
    sys.exit(0)

path = sys.argv[1]
kind = TYPES.get(os.path.splitext(path)[1].lstrip(".").lower())
if kind == "rar":
    with open(path, "rb") as start:
        kind = "rar5" if start.read(len(RAR5)) == RAR5 else "rar"
done = subprocess.run(["7z", "t", "-bd", "-pfanbase", *([f"-t{kind}"] if kind else []), path],
                      capture_output=True, text=True, errors="replace")
if done.returncode < 0:  # 7-Zip itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
def unnamed(message):
    """The message without the name of the entry or volume it is about."""
    return re.sub(r" ?: .*$", "", message)  # "CRC Failed : name of the entry", "Can't open volume: name"


errors = []
lines = [line.strip() for line in (done.stderr + "\n" + done.stdout).splitlines()]
for number, line in enumerate(lines):
    if line in ("ERRORS:", "WARNINGS:"):  # a list of what is wrong follows, up to a blank line
        for after in lines[number + 1:]:
            if not after:
                break
            errors.append(unnamed(after))
    elif re.match(r"(Open )?(ERROR|WARNING)S?: ", line):
        message = unnamed(re.sub(r"^(Open )?(ERROR|WARNING)S?: ", "", line))
        if message not in (path, os.path.basename(path)):
            errors.append(message)
if done.returncode != 0:
    print("\n".join(errors) or f"7-Zip exited with {done.returncode}", file=sys.stderr)
    sys.exit(1)
