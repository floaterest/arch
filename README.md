# Arch Linux + Hyprland

Backup to external HHD:
- ~/
  - (floaterest/dot)
  - .config/nvim
  - .local/share/fonts/
  - .mozilla/firefox/
  - .ssh/
  - .thunderbird/
  - Documents/
  - Downloads/
  - Music/
  - Pictures/
  - Templates/
  - Videos/
- /opt/vscodium-bin/data/
- /etc/greetd/

## Preinstallation

- [download](https://archlinux.org/download/) Arch Linux ISO
- [burn](https://wiki.archlinux.org/title/USB_flash_installation_medium) to USB
    ```bash
    cp path/to/archlinux-version-x86_64.iso /dev/sda
    ```

## Installation

Boot from USB

- connect wifi with [iwd](https://wiki.archlinux.org/title/iwd#iwctl), run `iwctl`, then
  ```bash
  device list
  adapter phy0 set-property Powered on
  station wlan0 scan
  station wlan0 get-networks
  station wlan0 connect {name}
  exit
  ```
  - if device is off, run `rfkill unblock wifi` [🔗](https://www.reddit.com/r/archlinux/comments/n4yycf/comment/gwybm5j/)
  - if iwctl says connected, but ping fails, run `dhcpcd wlan0` [🔗](https://www.reddit.com/r/archlinux/comments/hr3ci7/connected_with_iwctl_but_no_internet/)
- check connection with `ping gnu.org`

### Partition

`lsblk` to list devices



if need to create partitions:
- run `cfdisk /dev/sda`
- create free space as needed
- if no efi system exists: new, 100M, primary for `sda1`
- new, 16g, primary for `sda2` as swap
- new, the rest, primary for `sda3` as root and home
- `write` and exit cdfisk

`bash -c "$(curl 192.168.x.x:3000/hypr.sh)$` to run **mkfs** on sda or nvme

### Install Linux

run **prechroot**

- for NTFS devices, in `/mnt/etc/fstab` append `,noatime` at the 4th column [🔗](https://wiki.archlinux.org/title/NTFS#Improving_performance)

run `arch-chroot /mnt` to change root

- if dual boot, in `/etc/default/grub`, uncomment `GRUB_DISABLE_OS_PROBER=false` (last line)


run **post-chroot** to set up users and install GRUB

run **hyprland** to install Hyprland packages
- `sof-firmware` for sound
- `networkmanager` for networking
- `dhcpcd` for IP address
- `iwd` for WiFi 

run `mount /dev/sdb1 /mnt` to mount external harddrive

- copy /etc/greetd

run `su u` to switch to user

- copy backup to $HOME
  ```
  (rsync)
  ```
- download AUR packages from GitHub Actions 
  ```
  curl -O 192.168.x.x:3000/packages.zip
  ```
- unzip and install AUR packages
  ```
  sudo pacman -U *.zst
  ```
- run `broot` to install br

`exit` from arch-chroot, then `reboot`

## Postinstallation

- run `nmtui` to activate a connection
- run **postinstall**

**postinstall** to do more stuff (install more packages)
- OpenTabletDriver
    - import settings
    - if nonwacom table is not detected and `hid_uclogic` is in `lsmod`, add `blacklist hid_uclogic` to `/usr/lib/modprobe.d/blacklist.conf`

## Troubleshooting
### OpenTabletDriver
**Not wacom, cannot detect tablet**
```bash
sudo rmmod hid_uclogic
```

### Cannot Play Video [🔗](https://bbs.archlinux.org/viewtopic.php?id=273202)

```bash
systemctl --user mask wireplumber --now
```

## Keyboard Layout Resets after Login [🔗](https://bbs.archlinux.org/viewtopic.php?pid=2088382#p2088382)

Fcitx5's fault. Solution: set `kxkbrc` to immutable

```bash
sudo chattr +i ~/.config/kxkbrc
```

## Dolphin Opens Files with no Application Association [🔗](https://bbs.archlinux.org/viewtopic.php?pid=2169212#p2169212)

download plasma-workspace

```bash
sudo pacman -Sw plasma-workspace
tar xvf /var/cache/pacman/pkg/plasma-workspace-*.pkg.tar.zst
cp etc/xdg/menus/plasma-applications.menu ~/.config/menus/
kbuildsycoca6
```

## Fcitx5 Completion

toggle with `c-a-j`
