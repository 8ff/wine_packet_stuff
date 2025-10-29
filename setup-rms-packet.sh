#!/bin/bash

# Winlink RMS Packet Installation Script for Linux
# Installs Winlink RMS Packet using Wine on Debian-based systems
# Designed for fresh Debian 13 installations
# Automatically installs Wine, winetricks, and all dependencies
# Compatible with VARA FM installation using Pat wiki method

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - Use same prefix as VARA FM (Pat wiki method)
WINEPREFIX="$HOME/.wine-winlink"
WINEARCH="win32"
WINLINK_URL="https://downloads.winlink.org/Sysop%20Programs/RMS_Packet_install_2-1-51-0.zip"
INSTALL_DIR="$HOME/Downloads/winlink_install"

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

    if ! command -v wget &> /dev/null; then
        TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL wget"
    fi

    if ! command -v unzip &> /dev/null; then
        TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL unzip"
    fi

    if ! command -v curl &> /dev/null; then
        TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL curl"
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
        wget -O /tmp/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
        chmod +x /tmp/winetricks
        sudo mv /tmp/winetricks /usr/local/bin/winetricks

        print_info "Winetricks installed successfully"
    else
        print_info "Winetricks is already installed"
    fi

    print_info "System dependencies installed successfully"
}

# Create Wine prefix if it doesn't exist
create_wine_prefix() {
    if [ -d "$WINEPREFIX" ]; then
        print_info "Wine prefix already exists at $WINEPREFIX"
        return 0
    fi

    print_step "Creating Wine prefix at $WINEPREFIX"

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

# Configure base Wine environment
configure_base_wine() {
    print_step "Configuring base Wine environment..."

    # Set Windows version (XP is more compatible with older Windows apps)
    print_info "Setting Windows XP compatibility mode..."
    WINEPREFIX="$WINEPREFIX" winetricks -q winxp 2>/dev/null || true

    # Set sound to ALSA
    print_info "Configuring sound driver..."
    WINEPREFIX="$WINEPREFIX" winetricks -q sound=alsa 2>/dev/null || true

    print_info "Base Wine configuration completed"
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

    if ! command -v wget &> /dev/null; then
        MISSING_TOOLS="$MISSING_TOOLS wget"
    fi

    if ! command -v unzip &> /dev/null; then
        MISSING_TOOLS="$MISSING_TOOLS unzip"
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

# Download Winlink RMS Packet
download_winlink() {
    print_step "Downloading Winlink RMS Packet..."

    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    # Check if already downloaded
    if [ -f "RMS_Packet_install_2-1-51-0.zip" ]; then
        print_info "Winlink installer already downloaded"
    else
        print_info "Downloading from Winlink website..."
        wget -O "RMS_Packet_install_2-1-51-0.zip" "$WINLINK_URL" || {
            print_error "Failed to download Winlink RMS Packet"
            print_warning "Please download manually from: https://www.winlink.org/RMSPacketDownloads"
            print_warning "Save the file to: $INSTALL_DIR"
            read -p "Press Enter once you have downloaded the file..."
        }
    fi

    # Extract the installer
    print_info "Extracting installer..."
    if [ ! -f "RMS_Packet_install.exe" ]; then
        unzip -o "RMS_Packet_install_2-1-51-0.zip" || {
            print_error "Failed to extract Winlink installer"
            exit 1
        }
    fi

    print_info "Winlink RMS Packet download complete"
}

# Install additional Wine dependencies for Winlink
install_wine_dependencies() {
    print_step "Installing additional Wine dependencies for Winlink..."

    # Ensure winetricks is available
    if ! command -v winetricks &> /dev/null; then
        print_error "Winetricks not found - this should not happen!"
        print_error "Please report this issue"
        exit 1
    fi

    # Ensure Wine prefix exists
    if [ ! -d "$WINEPREFIX" ]; then
        print_error "Wine prefix does not exist at $WINEPREFIX"
        print_error "This should have been created earlier - something went wrong"
        exit 1
    fi

    # Install .NET Framework 4.0 (required by Winlink RMS Packet)
    print_info "Installing .NET Framework 4.0 (required by Winlink RMS Packet)..."
    print_warning "This installation may take 10-15 minutes..."
    print_warning "You may see some installer windows - follow the prompts"

    WINEPREFIX="$WINEPREFIX" winetricks -q dotnet40 2>&1 | grep -v "^wine: " || {
        print_warning ".NET 4.0 installation had issues, trying alternative method..."
        WINEPREFIX="$WINEPREFIX" winetricks dotnet40 || {
            print_warning "Standard .NET 4.0 failed, trying .NET 4.5..."
            WINEPREFIX="$WINEPREFIX" winetricks -q dotnet45 2>&1 | grep -v "^wine: " || true
        }
    }

    # Install Visual C++ runtimes that Winlink might need
    print_info "Installing Visual C++ runtimes..."
    WINEPREFIX="$WINEPREFIX" winetricks -q vcrun2008 2>/dev/null || true
    WINEPREFIX="$WINEPREFIX" winetricks -q vcrun2010 2>/dev/null || true
    WINEPREFIX="$WINEPREFIX" winetricks -q vcrun2012 2>/dev/null || true

    # Install MDAC for database access (RMS uses databases)
    print_info "Installing MDAC (Microsoft Data Access Components)..."
    WINEPREFIX="$WINEPREFIX" winetricks -q mdac28 2>/dev/null || true

    # Install some additional useful components
    print_info "Installing additional components..."
    WINEPREFIX="$WINEPREFIX" winetricks -q corefonts 2>/dev/null || true

    print_info "Wine dependencies installation complete"
}

# Install Winlink RMS Packet
install_winlink() {
    print_step "Installing Winlink RMS Packet..."

    cd "$INSTALL_DIR"

    # Find the installer
    local INSTALLER=""
    if [ -f "RMS_Packet_install.exe" ]; then
        INSTALLER="RMS_Packet_install.exe"
    elif [ -f "RMS Packet Setup.exe" ]; then
        INSTALLER="RMS Packet Setup.exe"
    else
        # Try to find any exe file in the directory
        INSTALLER=$(find . -maxdepth 1 -name "*.exe" | head -n1)
    fi

    if [ -z "$INSTALLER" ]; then
        print_error "Winlink installer executable not found"
        print_warning "Please check the contents of $INSTALL_DIR"
        exit 1
    fi

    print_info "Found installer: $INSTALLER"
    print_info "Starting Winlink RMS Packet installation..."
    print_warning "Follow the GUI installer prompts"
    print_warning "Use default installation paths when possible"

    # Run the installer
    WINEPREFIX="$WINEPREFIX" WINEARCH="$WINEARCH" wine "$INSTALLER"

    print_info "Winlink RMS Packet installation process completed"
}

# Configure Winlink for VARA FM
configure_winlink_vara() {
    print_step "Configuring Winlink for VARA FM integration..."

    print_info "Configuration notes for Winlink with VARA FM:"
    echo
    echo "  1. In Winlink RMS Packet, go to Settings -> TNC Setup"
    echo "  2. Select 'VARA FM' as the TNC type"
    echo "  3. Configure the following:"
    echo "     - VARA Host: localhost (or 127.0.0.1)"
    echo "     - VARA Control Port: 8300 (default)"
    echo "     - VARA Data Port: 8301 (default)"
    echo "  4. Ensure VARA FM is running before starting Winlink"
    echo
    print_warning "Note: VARA FM must be registered for full functionality"
}


# Test Winlink installation
test_winlink() {
    print_step "Verifying Winlink RMS Packet installation..."

    local RMS_EXE=$(find "$WINEPREFIX/drive_c" -name "RMS Packet.exe" -o -name "RMSPacket.exe" 2>/dev/null | head -n1)

    if [ -z "$RMS_EXE" ]; then
        print_warning "Winlink RMS Packet executable not found"
        print_warning "Installation may not have completed successfully"
        return 1
    fi

    print_info "Found Winlink RMS Packet at: $RMS_EXE"
    print_info "Installation verified successfully"
}

# Main installation flow
main() {
    echo "============================================"
    echo "   Winlink RMS Packet Installation Script"
    echo "============================================"
    echo
    print_info "This script installs Winlink RMS Packet to work with VARA FM"
    print_info "Using Wine prefix: $WINEPREFIX"
    print_info "Designed for fresh Debian 13 installations"
    echo

    # Always ensure all system dependencies are properly installed
    # This handles both fresh installs and incomplete installations
    print_info "Ensuring all system dependencies are installed..."
    install_system_dependencies

    # Create Wine prefix if it doesn't exist
    create_wine_prefix

    # Configure base Wine environment
    configure_base_wine

    # Continue with Winlink-specific installation
    download_winlink
    install_wine_dependencies
    install_winlink
    configure_winlink_vara
    test_winlink

    # Determine scripts directory (where this script is located)
    local SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    echo
    echo "============================================"
    echo "   Installation Complete!"
    echo "============================================"
    print_info "Winlink RMS Packet has been installed"
    echo
    print_info "Launch scripts available in scripts folder:"
    print_info "  1. $SCRIPTS_DIR/launch-winlink-rms.sh         - Launch Winlink only"
    print_info "  2. $SCRIPTS_DIR/launch-vara-and-winlink.sh    - Launch both VARA and Winlink"
    echo
    print_info "Configuration steps:"
    print_info "  1. Start VARA FM first (or use combined launcher)"
    print_info "  2. Configure Winlink to use VARA FM as TNC"
    print_info "  3. Use localhost:8300 for VARA control port"
    echo
    print_warning "Note: VARA FM must be registered for full functionality"
    print_warning "Visit https://rosmodem.wordpress.com/ for VARA registration"
}

# Run main function
main "$@"