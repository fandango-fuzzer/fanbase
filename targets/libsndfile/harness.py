"""Ask libsndfile about a file (through the soundfile package): exit 0 if it opens and reads every frame, else say why and exit 1.

libsndfile opens some files whose audio it then cannot decode (an Ogg Vorbis stream with a broken setup header), and reading
them gives no frame and no error: a file that says it has frames and gives none is rejected.
"""

import sys

import soundfile

BLOCK = 65536  # frames read at a time, so that a header that claims a huge length costs nothing up front

try:
    with soundfile.SoundFile(sys.argv[1]) as sound:
        read = 0
        while True:
            got = len(sound.read(BLOCK))
            if not got:
                break
            read += got
        if read == 0 and sound.frames != 0:
            print(f"no audio decoded, though the file says it has {sound.frames} frames", file=sys.stderr)
            sys.exit(1)
except Exception as exc:  # whatever soundfile raises is a rejection
    print(f"{type(exc).__name__}: {exc}", file=sys.stderr)
    sys.exit(1)
