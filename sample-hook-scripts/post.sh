#! /bin/sh

# Hook script that after files have been processed in ANT
# but before they are copied to their final destination.

set -euo pipefail

DIST_PENDING_DIR="$1";
shift;

echo "Running post.sh" 1>&2

echo "DIR: $DIST_PENDING_DIR" 1>&2
echo "INPUT FILE(S)" 1>&2
echo "$@" 1>&2
