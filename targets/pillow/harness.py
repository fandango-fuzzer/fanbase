"""Ask Pillow about a file: exit 0 if it opens and decodes every frame, else say why and exit 1."""

import sys

from PIL import Image, ImageSequence

# Beyond twice this many pixels Pillow refuses (DecompressionBombError), which the target
# calls a resource limit: the file asks for more than it may have.
Image.MAX_IMAGE_PIXELS = 100_000_000
MAX_FRAMES = 100

try:
    with Image.open(sys.argv[1]) as image:
        for number, frame in enumerate(ImageSequence.Iterator(image)):
            frame.load()
            if number >= MAX_FRAMES:
                break
except Exception as exc:  # whatever Pillow raises is a rejection
    print(f"{type(exc).__name__}: {exc}", file=sys.stderr)
    sys.exit(1)
