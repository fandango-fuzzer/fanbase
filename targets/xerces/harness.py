"""Ask Xerces-C++ about a file: exit 0 if SAX2Count reads it as well-formed XML, else say why and exit 1.

SAX2Count is one of Xerces' sample programs: it parses a document and counts what is in it. It is told not to validate
(-v=never). It says where an error is ("Fatal Error at file ..., line ..., char ...") and then the message: the message
is what is printed, with the names it quotes left out, so that the same reason is counted as one. Xerces fetches the
external DTD a document names, over the network too: every proxy it could use points at a port where nothing
listens, so that a URL in a file is never fetched and the document is refused, as one is whose DTD is not there.
"""

import os
import re
import signal
import subprocess
import sys

NOWHERE = "http://127.0.0.1:9"  # the discard port: nothing answers there

if sys.argv[1:] == ["--version"]:  # SAX2Count does not say which version it is; its package does
    asked = subprocess.run(["dpkg-query", "-W", "-f=${Version}", "libxerces-c-samples"], capture_output=True, text=True)
    print(asked.stdout.strip() or "unknown")
    sys.exit(0)

offline = dict(os.environ, no_proxy="", NO_PROXY="", **{name: NOWHERE for name in (
    "http_proxy", "HTTP_PROXY", "https_proxy", "HTTPS_PROXY", "ftp_proxy", "FTP_PROXY", "all_proxy", "ALL_PROXY")})
done = subprocess.run(["SAX2Count", "-v=never", sys.argv[1]], capture_output=True, text=True, errors="replace", env=offline)
if done.returncode < 0:  # SAX2Count itself was killed or crashed: die the same way, so that it counts as that
    signal.signal(-done.returncode, signal.SIG_DFL)
    os.kill(os.getpid(), -done.returncode)
if done.returncode != 0:
    said = re.findall(r"Message: (.*)", done.stderr + done.stdout)
    said = [re.sub(r"'[^']*'", "X", line.strip()) for line in said]
    print("\n".join(said) or (done.stderr + done.stdout).strip()[-300:] or f"SAX2Count exited with {done.returncode}",
          file=sys.stderr)
    sys.exit(1)
