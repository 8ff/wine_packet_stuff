#!/bin/bash

# VARA FM Launch Script (Pat Wiki Method)
# Uses the exact environment variables from Pat wiki

WINEPREFIX="$HOME/.wine-winlink"
WINEARCH="win32"
WINEDEBUG="-all"  # Suppress debug messages

# Find VARA FM executable
VARA_EXE=$(find "$WINEPREFIX/drive_c" -name "VARAFM.exe" 2>/dev/null | head -n1)

if [ -z "$VARA_EXE" ]; then
    echo "Error: VARA FM not found. Please install it first."
    exit 1
fi

echo "Starting VARA FM..."
echo "Wine prefix: $WINEPREFIX"
echo "Executable: $VARA_EXE"

# Launch with Pat wiki recommended environment
env WINEPREFIX="$WINEPREFIX" \
    WINEARCH="$WINEARCH" \
    WINEDEBUG="$WINEDEBUG" \
    wine "$VARA_EXE"
