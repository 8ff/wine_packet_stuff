#!/bin/bash

# Complete Wine Configuration Cleanup Script
# Removes all Wine prefixes and configurations for a fresh start

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo -e "${RED}============================================${NC}"
echo -e "${RED}   Wine Configuration Complete Cleanup${NC}"
echo -e "${RED}============================================${NC}"
echo

print_warning "This script will completely remove:"
echo "  - All Wine prefixes (.wine, .wine_vara, .wine-winlink)"
echo "  - Wine application menu entries"
echo "  - Wine desktop files"
echo "  - Local winetricks cache"
echo

read -p "Are you sure you want to remove ALL Wine configurations? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Cancelled by user"
    exit 0
fi

# Kill any running Wine processes
print_step "Stopping all Wine processes..."
wineserver -k 2>/dev/null || true
pkill -9 wine 2>/dev/null || true
pkill -9 wineserver 2>/dev/null || true
sleep 2

# Remove Wine prefixes
print_step "Removing Wine prefixes..."

if [ -d "$HOME/.wine" ]; then
    print_info "Removing ~/.wine"
    rm -rf "$HOME/.wine"
fi

if [ -d "$HOME/.wine_vara" ]; then
    print_info "Removing ~/.wine_vara"
    rm -rf "$HOME/.wine_vara"
fi

if [ -d "$HOME/.wine-winlink" ]; then
    print_info "Removing ~/.wine-winlink"
    rm -rf "$HOME/.wine-winlink"
fi

# Remove any other Wine prefixes that might exist
for prefix in "$HOME"/.wine-*; do
    if [ -d "$prefix" ]; then
        print_info "Removing $prefix"
        rm -rf "$prefix"
    fi
done

# Remove Wine application menu entries
print_step "Removing Wine application menu entries..."

if [ -d "$HOME/.local/share/applications/wine" ]; then
    print_info "Removing Wine application menu entries"
    rm -rf "$HOME/.local/share/applications/wine"
fi

# Remove Wine desktop entries
for desktop_file in "$HOME/.local/share/applications"/wine-*.desktop; do
    if [ -f "$desktop_file" ]; then
        rm -f "$desktop_file"
    fi
done

# Remove VARA FM desktop entries if they exist
if [ -f "$HOME/.local/share/applications/vara-fm.desktop" ]; then
    print_info "Removing VARA FM desktop entry"
    rm -f "$HOME/.local/share/applications/vara-fm.desktop"
fi

if [ -f "$HOME/Desktop/vara-fm.desktop" ]; then
    print_info "Removing VARA FM desktop shortcut"
    rm -f "$HOME/Desktop/vara-fm.desktop"
fi

# Remove Wine file associations
print_step "Removing Wine file associations..."

if [ -f "$HOME/.local/share/applications/mimeinfo.cache" ]; then
    print_info "Cleaning up MIME cache"
    sed -i '/wine/d' "$HOME/.local/share/applications/mimeinfo.cache" 2>/dev/null || true
fi

# Remove winetricks cache (optional)
read -p "Do you want to remove winetricks cache? This will require re-downloading components later (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "$HOME/.cache/winetricks" ]; then
        print_info "Removing winetricks cache"
        rm -rf "$HOME/.cache/winetricks"
    fi
fi

# Remove launch scripts created by our installers
print_step "Removing launch scripts..."

LAUNCH_SCRIPTS=(
    "$HOME/run-vara-fm.sh"
    "$HOME/start-vara-fm.sh"
    "$HOME/launch-vara-fm.sh"
    "$HOME/launch-winlink-rms.sh"
    "$HOME/launch-vara-and-winlink.sh"
)

for script in "${LAUNCH_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        print_info "Removing $script"
        rm -f "$script"
    fi
done

# Clean up any Wine temp files
print_step "Cleaning up Wine temporary files..."

if [ -d "/tmp/.wine-$USER" ]; then
    rm -rf "/tmp/.wine-$USER"
fi

# Clean up any leftover Wine registry files
if [ -d "$HOME/.local/share/icons/hicolor" ]; then
    find "$HOME/.local/share/icons/hicolor" -name "*wine*" -delete 2>/dev/null || true
fi

print_step "Verifying cleanup..."

# Check if main directories are removed
REMOVED_COUNT=0
TOTAL_COUNT=0

check_removed() {
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    if [ ! -e "$1" ]; then
        print_info "✓ $1 removed successfully"
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    else
        print_warning "✗ $1 still exists"
    fi
}

check_removed "$HOME/.wine"
check_removed "$HOME/.wine_vara"
check_removed "$HOME/.wine-winlink"
check_removed "$HOME/.local/share/applications/wine"

echo
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   Cleanup Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo
print_info "Removed $REMOVED_COUNT out of $TOTAL_COUNT checked items"
print_info "Wine configurations have been completely removed"
echo
print_info "You can now run a fresh installation using:"
echo "  1. For VARA FM (Pat wiki method):"
echo "     cd ~/scripts"
echo "     ./setup-vara.sh"
echo
echo "  2. For Winlink RMS Packet:"
echo "     cd ~/scripts"
echo "     ./setup-rms-packet.sh"
echo
print_warning "Note: Wine itself is still installed. To remove Wine completely, use:"
print_warning "  sudo apt-get remove --purge wine wine32 wine64"