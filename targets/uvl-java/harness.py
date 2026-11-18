"""Ask uvl-parser's Java parser about a file: exit 0 if it parses, else say why and exit 1.

The parser comes from a checkout of uvl-parser that has been built (`cd java && mvn package`): set
UVL_PARSER_ROOT to it. Its jar does not bring the ANTLR runtime, which is taken from Maven's local
repository (UVL_ANTLR_JAR names another). Harness.java is compiled once, into a cache next to the jar.
"""

import glob
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ANTLR_VERSION = "4.13.2"


def fail(message: str, status: int = 1) -> None:
    print(message, file=sys.stderr)
    sys.exit(status)


root = os.environ.get("UVL_PARSER_ROOT")
if not root:
    fail("UVL_PARSER_ROOT is not set: it names the uvl-parser checkout whose Java parser is asked", 127)
jars = sorted(p for p in glob.glob(os.path.join(root, "java", "target", "uvl-parser-*.jar"))
              if not p.endswith(("-sources.jar", "-javadoc.jar")))
if not jars:
    fail(f"no uvl-parser jar in {root}/java/target: build it with `mvn package`", 127)
antlr = os.environ.get("UVL_ANTLR_JAR") or os.path.expanduser(
    f"~/.m2/repository/org/antlr/antlr4-runtime/{ANTLR_VERSION}/antlr4-runtime-{ANTLR_VERSION}.jar")
if not os.path.exists(antlr):
    fail(f"no ANTLR runtime at {antlr}: set UVL_ANTLR_JAR", 127)

classpath = os.pathsep.join([jars[-1], antlr])
cache = Path(root, "java", "target", "fanbase-harness")
compiled = cache / "Harness.class"
source = HERE / "Harness.java"
if not compiled.exists() or compiled.stat().st_mtime < source.stat().st_mtime:
    cache.mkdir(parents=True, exist_ok=True)
    done = subprocess.run(["javac", "-cp", classpath, "-d", str(cache), str(source)], capture_output=True, text=True)
    if done.returncode != 0:
        fail(f"cannot compile the harness: {done.stderr.strip()}", 127)

done = subprocess.run(["java", "-Xss8m", "-cp", os.pathsep.join([str(cache), classpath]), "Harness", sys.argv[1]],
                      capture_output=True, text=True, stdin=subprocess.DEVNULL)
sys.stderr.write(done.stderr)
sys.exit(done.returncode)
