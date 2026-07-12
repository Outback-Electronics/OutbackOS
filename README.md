# Outback OS

Outback OS is a custom Linux-based operating-system ecosystem developed by Outback Electronics.

The current developer preview includes:

- A custom Qt/QML shell
- A custom Settings application
- A Debian Trixie live-image build configuration
- A Weston-based Wayland graphical session
- UEFI and legacy BIOS boot support
- Wi-Fi, Bluetooth, audio and brightness foundations

## Project status

Outback OS is currently an early developer preview. It is not ready for production use.

## Repository layout

- `shell/` - Outback Shell
- `apps/settings/` - Outback Settings
- `iso/` - Debian live-build configuration

## Building

```bash
cd iso
sudo lb clean
lb config
sudo lb build
```

The generated ISO is excluded from Git because release images should be distributed through GitHub Releases rather than committed to the repository.
