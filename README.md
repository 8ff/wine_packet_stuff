# Ham Radio Winlink & VARA Setup Scripts

Automated installation scripts for running Winlink and VARA FM on Linux using Wine.

**Tested on Debian 13** - Written specifically for Debian, may work on Ubuntu.

## What's Included

### Setup Scripts
- `setup-vara.sh` - Installs VARA FM digital modem
- `setup-winlink-express.sh` - Installs Winlink Express (email client)
- `setup-rms-packet.sh` - Installs RMS Packet (gateway software)

### Launch Scripts
- `launch-vara-fm.sh` - Starts VARA FM
- `launch-winlink-express.sh` - Starts Winlink Express
- `launch-winlink-rms.sh` - Starts RMS Packet
- `launch-vara-and-winlink.sh` - Starts VARA FM and RMS Packet together

### Utility
- `clean-wine-config.sh` - Remove all Wine configurations for fresh start

## Download the scripts
- Option A: Using Git (recommended)
  - Install Git if needed: `sudo apt install -y git`
  - Clone the repo: `git clone https://github.com/8ff/wine_packet_stuff.git`
  - Enter the folder: `cd wine_packet_stuff`
- Option B: Download ZIP
  - Open https://github.com/8ff/wine_packet_stuff
  - Click the green "Code" button → "Download ZIP"
  - Extract the ZIP, then open a terminal in the extracted `wine_packet_stuff` folder

Then follow Quick Start below.

## Quick Start

```bash
# Make scripts executable
chmod +x *.sh

# Install VARA FM
./setup-vara.sh

# Install Winlink Express (most users want this)
./setup-winlink-express.sh

# Launch programs
./launch-vara-fm.sh
./launch-winlink-express.sh
```

## VARA FM Configuration
When connecting VARA to Winlink:
- Host: localhost
- Control Port: 8300
- Data Port: 8301

## Notes
- Scripts automatically install Wine and all dependencies
- VARA FM and RMS Packet share the same Wine prefix (`~/.wine-winlink`)
- Winlink Express uses a separate prefix (`~/.wine-winlink-express`)
- Always start VARA FM before Winlink if using them together

## License
Scripts are free to use. VARA and Winlink software have their own licensing terms.
