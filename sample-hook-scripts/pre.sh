#! /bin/sh

# Hook script that runs before files are processed in ANT.

set -euo pipefail

SOURCE_DIR="$1" 1>&2
shift

echo "Running pre.sh" 1>&2
echo "DIR: ${SOURCE_DIR}" 1>&2
echo "INPUT FILE(S)" 1>&2
echo "$@" 1>&2
