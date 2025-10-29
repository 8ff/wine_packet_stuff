#!/bin/bash

# Combined VARA FM and Winlink RMS Packet Launch Script
# Starts both applications in the correct order

WINEPREFIX="$HOME/.wine-winlink"
WINEARCH="win32"
WINEDEBUG="-all"

echo "Starting VARA FM and Winlink RMS Packet..."

# Start VARA FM first (in background)
echo "Starting VARA FM..."
VARA_EXE=$(find "$WINEPREFIX/drive_c" -name "VARAFM.exe" 2>/dev/null | head -n1)

if [ -n "$VARA_EXE" ]; then
    env WINEPREFIX="$WINEPREFIX" WINEARCH="$WINEARCH" WINEDEBUG="$WINEDEBUG" \
        wine "$VARA_EXE" &
    VARA_PID=$!

    # Wait a moment for VARA to start
    sleep 5

    echo "VARA FM started (PID: $VARA_PID)"
else
    echo "Warning: VARA FM not found"
fi

# Start Winlink RMS Packet
echo "Starting Winlink RMS Packet..."
RMS_EXE=$(find "$WINEPREFIX/drive_c" -name "RMS Packet.exe" -o -name "RMSPacket.exe" 2>/dev/null | head -n1)

if [ -n "$RMS_EXE" ]; then
    env WINEPREFIX="$WINEPREFIX" WINEARCH="$WINEARCH" WINEDEBUG="$WINEDEBUG" \
        wine "$RMS_EXE"
else
    echo "Error: Winlink RMS Packet not found"
    exit 1
fi

# When RMS Packet closes, also close VARA FM
if [ -n "$VARA_PID" ]; then
    echo "Stopping VARA FM..."
    kill $VARA_PID 2>/dev/null || true
fi
