#!/bin/bash

# Winlink RMS Packet Launch Script
# Uses the same Wine prefix as VARA FM (Pat wiki method)

WINEPREFIX="$HOME/.wine-winlink"
WINEARCH="win32"
WINEDEBUG="-all"  # Suppress debug messages

# Find RMS Packet executable
RMS_EXE=$(find "$WINEPREFIX/drive_c" -name "RMS Packet.exe" -o -name "RMSPacket.exe" 2>/dev/null | head -n1)

if [ -z "$RMS_EXE" ]; then
    echo "Error: Winlink RMS Packet not found. Please install it first."
    exit 1
fi

echo "Starting Winlink RMS Packet..."
echo "Wine prefix: $WINEPREFIX"
echo "Executable: $RMS_EXE"

# Launch Winlink RMS Packet
env WINEPREFIX="$WINEPREFIX" \
    WINEARCH="$WINEARCH" \
    WINEDEBUG="$WINEDEBUG" \
    wine "$RMS_EXE"
