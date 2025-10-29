#!/bin/bash

# Winlink Express Launch Script
# Uses separate Wine prefix (requires Windows 7)

WINEPREFIX="$HOME/.wine-winlink-express"
WINEARCH="win32"
WINEDEBUG="-all"  # Suppress debug messages

# Find Winlink Express executable
WINLINK_EXE=$(find "$WINEPREFIX/drive_c" -name "Winlink Express.exe" -o -name "WinlinkExpress.exe" 2>/dev/null | head -n1)

if [ -z "$WINLINK_EXE" ]; then
    echo "Error: Winlink Express not found. Please install it first."
    exit 1
fi

echo "Starting Winlink Express..."
echo "Wine prefix: $WINEPREFIX"
echo "Executable: $WINLINK_EXE"

# Launch Winlink Express
env WINEPREFIX="$WINEPREFIX" \
    WINEARCH="$WINEARCH" \
    WINEDEBUG="$WINEDEBUG" \
    wine "$WINLINK_EXE"
