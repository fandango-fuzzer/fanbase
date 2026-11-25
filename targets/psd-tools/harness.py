"""Ask psd-tools about a Photoshop document: exit 0 if it opens it and composites it (from its layers where it has
them, else its merged image), else say why and exit 1."""

import sys
import warnings

from psd_tools import PSDImage

warnings.simplefilter("ignore")  # it warns about what it composites roughly, which is not a rejection

try:
    psd = PSDImage.open(sys.argv[1])
    psd.composite()
except Exception as exc:  # whatever psd-tools raises is a rejection
    print(f"{type(exc).__name__}: {exc}", file=sys.stderr)
    sys.exit(1)
