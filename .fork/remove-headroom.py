#!/usr/bin/env python3
"""Drop the optional headroom sidecar from docker-compose.yaml.

VansRouter's compose may carry a headroom service (and its depends_on entry) that
this fork does not run. The upstream merge brings it back on every sync, so it is
removed here rather than by hand.

Run from the repository root, after the merge is staged:

    python3 .fork/remove-headroom.py
"""

import re
import sys

path = "docker-compose.yaml"

try:
    with open(path) as fh:
        text = fh.read()
except FileNotFoundError:
    print("no docker-compose.yaml, nothing to strip", file=sys.stderr)
    sys.exit(0)

before = text

# The headroom service block, up to the next service key or the volumes section.
text = re.sub(r"\n  headroom:.*?(?=\n(?:  [a-z]|\nvolumes:))", "", text, flags=re.DOTALL)
# Any reference to its URL.
text = re.sub(r"HEADROOM_URL:.*\n", "", text)
# Its depends_on entry.
text = re.sub(r"depends_on:\n\s+headroom:\n\s+condition: service_started\n", "", text)

if text == before:
    print("no headroom references found")
    sys.exit(0)

with open(path, "w") as fh:
    fh.write(text)

print("headroom removed from docker-compose.yaml")