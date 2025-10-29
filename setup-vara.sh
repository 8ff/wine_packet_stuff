#!/bin/bash

# VARA FM Setup Script - Following Pat Wiki Method
# Based on: https://github.com/la5nta/pat/wiki/VARA
# Designed for fresh Debian 13 installations
# Automatically installs Wine, winetricks, and all dependencies

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WINEPREFIX="$HOME/.wine-winlink"
WINEARCH="win32"

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

# Install system dependencies
install_system_dependencies() {
    print_step "Installing system dependencies..."

    # Enable 32-bit architecture support (required for Wine 32-bit)
    print_info "Enabling 32-bit architecture support..."
    if ! dpkg --print-foreign-architectures | grep -q i386; then
        sudo dpkg --add-architecture i386
        print_info "32-bit architecture enabled"
    else
        print_info "32-bit architecture already enabled"
    fi

    # Update package list
    print_info "Updating package list..."
    sudo apt-get update

    # Install Wine and dependencies if not present
    if ! command -v wine &> /dev/null; then
        print_info "Installing Wine and dependencies..."
        sudo apt-get install -y wine wine32:i386 wine64 libwine libwine:i386 fonts-wine
    else
        print_info "Wine is already installed"
        # Check if wine32 is installed
        if ! dpkg -l | grep -q wine32:i386; then
            print_info "Installing Wine 32-bit support..."
            sudo apt-get install -y wine32:i386 libwine:i386
        fi
    fi

    # Install required tools
    local TOOLS_TO_INSTALL=""

    if ! command -v curl &> /dev/null; then
        TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL curl"
    fi

    if ! command -v wget &> /dev/null; then
        TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL wget"
    fi

    if ! command -v unzip &> /dev/null; then
        TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL unzip"
    fi

    if ! command -v cabextract &> /dev/null; then
        TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL cabextract"
    fi

    if [ -n "$TOOLS_TO_INSTALL" ]; then
        print_info "Installing additional tools:$TOOLS_TO_INSTALL"
        sudo apt-get install -y $TOOLS_TO_INSTALL
    fi

    # Install winetricks if not present
    if ! command -v winetricks &> /dev/null; then
        print_info "Installing winetricks..."

        # Download winetricks
        curl -o /tmp/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
        chmod +x /tmp/winetricks
        sudo mv /tmp/winetricks /usr/local/bin/winetricks

        print_info "Winetricks installed successfully"
    else
        print_info "Winetricks is already installed"
    fi

    print_info "System dependencies installed successfully"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."

    # Check if Wine is installed
    if ! command -v wine &> /dev/null; then
        print_warning "Wine is not installed"
        return 1
    fi

    # Check for required tools
    local MISSING_TOOLS=""

    if ! command -v curl &> /dev/null; then
        MISSING_TOOLS="$MISSING_TOOLS curl"
    fi

    if ! command -v winetricks &> /dev/null; then
        MISSING_TOOLS="$MISSING_TOOLS winetricks"
    fi

    if [ -n "$MISSING_TOOLS" ]; then
        print_warning "Missing tools:$MISSING_TOOLS"
        return 1
    fi

    print_info "Prerequisites checked successfully"
    return 0
}

# Step 1: Create Wine prefix
create_wine_prefix() {
    print_step "Creating Wine prefix at $WINEPREFIX"

    if [ -d "$WINEPREFIX" ]; then
        print_warning "Wine prefix already exists. Removing it..."
        rm -rf "$WINEPREFIX"
    fi

    print_info "Creating new 32-bit Wine prefix..."
    print_warning "This may take a few minutes..."

    # Wine wineboot may return non-zero even on success, so don't fail on it
    WINEPREFIX="$WINEPREFIX" WINEARCH="$WINEARCH" wine wineboot 2>/dev/null || true

    # Wait for wineserver to finish
    WINEPREFIX="$WINEPREFIX" wineserver -w

    # Verify the prefix was actually created
    if [ ! -d "$WINEPREFIX" ]; then
        print_error "Failed to create Wine prefix at $WINEPREFIX"
        exit 1
    fi

    print_info "Wine prefix created successfully"
}

# Step 2: Configure Wine with winetricks
configure_wine() {
    print_step "Configuring Wine with winetricks (as per Pat wiki)"

    # Set Windows XP mode
    print_info "Setting Windows XP compatibility mode..."
    WINEPREFIX="$WINEPREFIX" winetricks winxp

    # Set sound to ALSA
    print_info "Setting sound to ALSA..."
    WINEPREFIX="$WINEPREFIX" winetricks sound=alsa

    # Install .NET Framework 3.5 SP1
    print_info "Installing .NET Framework 3.5 SP1 (this may take a while)..."
    WINEPREFIX="$WINEPREFIX" winetricks dotnet35sp1

    # Install Visual Basic 6 runtime
    print_info "Installing Visual Basic 6 runtime..."
    WINEPREFIX="$WINEPREFIX" winetricks vb6run

    # Install Visual C++ 2015 runtime
    print_info "Installing Visual C++ 2015 runtime..."
    WINEPREFIX="$WINEPREFIX" winetricks vcrun2015

    print_info "Wine configuration completed"
}

# Step 3: Download and Install VARA FM
install_vara() {
    print_step "Downloading and Installing VARA FM"

    local VARA_URL="https://downloads.winlink.org/VARA%20Products/VARA%20FM%20v4.3.9%20setup.zip"
    local INSTALL_DIR="$HOME/Downloads/vara_install"
    local VARA_INSTALLER=""

    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    # Check if already downloaded
    if [ -f "VARA FM v4.3.9 setup.exe" ] || [ -f "VARAFM_setup.exe" ]; then
        print_info "VARA FM installer already downloaded"
    else
        print_info "Downloading VARA FM from Winlink..."
        wget -O "VARA_FM_setup.zip" "$VARA_URL" || {
            print_error "Failed to download VARA FM"
            print_warning "Please download manually from: https://rosmodem.wordpress.com/"
            print_warning "Save the file to: $INSTALL_DIR"
            read -p "Press Enter once you have downloaded the file..."
        }

        # Extract the installer
        if [ -f "VARA_FM_setup.zip" ]; then
            print_info "Extracting installer..."
            unzip -o "VARA_FM_setup.zip" || {
                print_error "Failed to extract VARA FM installer"
                exit 1
            }
        fi
    fi

    # Find the installer
    VARA_INSTALLER=$(find "$INSTALL_DIR" -maxdepth 1 -name "*VARA*FM*.exe" -o -name "*setup*.exe" 2>/dev/null | head -n1)

    if [ -z "$VARA_INSTALLER" ]; then
        # Try looking in Downloads folder as fallback
        VARA_INSTALLER=$(find ~/Downloads -maxdepth 1 \( -name "*VARA*FM*setup*.exe" -o -name "*VARA*FM*.exe" \) 2>/dev/null | head -n1)
    fi

    if [ -z "$VARA_INSTALLER" ]; then
        print_error "VARA FM installer not found"
        print_warning "Please check the contents of $INSTALL_DIR"
        exit 1
    fi

    print_info "Found installer: $(basename "$VARA_INSTALLER")"
    print_info "Installing VARA FM (follow the GUI installer)..."
    print_warning "Use default installation paths when possible"

    # Run installer
    WINEPREFIX="$WINEPREFIX" WINEARCH="$WINEARCH" wine "$VARA_INSTALLER"

    print_info "VARA FM installation completed"
}

# Verify VARA FM installation
verify_vara() {
    print_step "Verifying VARA FM installation..."

    local VARA_EXE=$(find "$WINEPREFIX/drive_c" -name "VARAFM.exe" 2>/dev/null | head -n1)

    if [ -z "$VARA_EXE" ]; then
        print_warning "VARA FM executable not found"
        print_warning "Installation may not have completed successfully"
        return 1
    fi

    print_info "Found VARA FM at: $VARA_EXE"
    print_info "Installation verified successfully"
}

# Main installation flow
main() {
    echo "============================================"
    echo "   VARA FM Setup - Pat Wiki Method"
    echo "============================================"
    echo
    print_info "This script follows the exact instructions from:"
    print_info "https://github.com/la5nta/pat/wiki/VARA"
    print_info "Designed for fresh Debian 13 installations"
    echo

    # Always ensure all system dependencies are properly installed
    # This handles both fresh installs and incomplete installations
    print_info "Ensuring all system dependencies are installed..."
    install_system_dependencies

    create_wine_prefix
    configure_wine
    install_vara
    verify_vara

    # Determine scripts directory (where this script is located)
    local SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    echo
    echo "============================================"
    echo "   Installation Complete!"
    echo "============================================"
    print_info "VARA FM has been installed successfully"
    echo
    print_info "Launch scripts available in scripts folder:"
    print_info "  1. $SCRIPTS_DIR/launch-vara-fm.sh          - Launch VARA FM only"
    print_info "  2. $SCRIPTS_DIR/launch-vara-and-winlink.sh - Launch both VARA and Winlink"
    echo
    print_warning "If you encounter OCX errors, run:"
    print_warning "  WINEPREFIX=$WINEPREFIX winetricks comctl32ocx"
    echo
    print_warning "Note: VARA FM must be registered for full functionality"
    print_warning "Visit https://rosmodem.wordpress.com/ for VARA registration"
}

# Run main function
main "$@"