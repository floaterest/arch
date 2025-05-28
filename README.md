# Arch Linux Installation

## Backup

- floaterest/dot
- ~/
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

## Preinstallation

- [download](https://archlinux.org/download/) ISO
- [burn](https://wiki.archlinux.org/title/USB_flash_installation_medium)
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
  - if device is off, do `rfkill unblock wifi` [🔗](https://www.reddit.com/r/archlinux/comments/n4yycf/comment/gwybm5j/)
  - if iwctl says connected, but ping fails, do `dhcpcd wlan0` [🔗](https://www.reddit.com/r/archlinux/comments/hr3ci7/connected_with_iwctl_but_no_internet/)
- check connection with `ping gnu.org`
- ctrl-L to clear screen

### Partition

`bash -c "$(curl 192.168.x.x:3000/script.sh)$` to run script

`lsblk` to list devices

`cfdisk /dev/sda`
- create free space as needed
- no efi system exists iff new, 100M, primary for `sda1`
- new, 16g, primary for `sda2` as swap
- new, the rest, primary for `sda3` as root and home
- `write` and exit cdfisk
- `lsblk` to list partitions

run **mkfs**

### Install

run **pacstrap**
- `sof-firmware` is for sound
- `networkmanager` is for networking
- `dhcpcd` is for IP address
- `iwd` is for WiFi (in case of emergency)

for NTFS devices, in `/mnt/etc/fstab` append `,noatime` at the 4th column [🔗](https://wiki.archlinux.org/title/NTFS#Improving_performance)

change root with `arch-chroot /mnt`

- if dual boot
  - run `pacman -S os-prober`
  - in `/etc/default/grub`, uncomment `GRUB_DISABLE_OS_PROBER=false` (last line)


run **localgen + grub install**

run **pacman**

install grub theme
```bash
git clone https://github.com/vinceliuice/grub2-themes.git
cd grub2-themes
sudo ./install.sh -t stylish
```

`exit` from arch-chroot, then `reboot`

## Postinstallation

- customise desktop

### Connect Wifi
- Classic, blowfish encrypted file
- empty password for KDE Wallet

### System Settings
- Quick Settings: Breeze Dark
- Input & Output
  - Mouse & Touchpad > Touchpad: Natural scrolling
  - Display & Monitor
  - Keyboard > Add: DQ
- Appreance & Style
  - Colors & Themes > Login Screen (SDDM): Breeze
- Apps & Windows
  - Window Management > Window Behavior: focus follows mouse, delay by 0ms

### Setup
- restore backup
- run **paru** to install paru
- run **misc** to install more packages
- firefox
    - copy `(/)etc/environment` to enable firefox touchscreen [🔗](https://wiki.archlinux.org/title/Firefox/Tweaks#Enable_touchscreen_gestures)
- run `broot` once to generate `br`
- logout to load configs
    - if screen blurry, use wayland
- copy `data` to `/opt/vscodium-bin/data`
- open `nvim` to install packages
- [OpenTabletDriver](https://aur.archlinux.org/packages/opentabletdriver)
    <!-- - if wacom, copy `(/)etc/X11/xorg.conf.d/00-wacom.conf`
    - if wacom and x11, install `xf86-input-wacom`
    - ensure `wacom` module is loaded in `lsmod`
        - if not, remove `/usr/lib/modprobe.d/99-opentabletdriver.conf` -->
    - import settings
    - if nonwacom table is not detected and `hid_uclogic` is in `lsmod`, add `blacklist hid_uclogic` to `/usr/lib/modprobe.d/blacklist.conf`
    and run `sudo mkinitcpio -P`
- install japanese, go to [Github Actions](https://github.com/liuyulo/arch/actions/workflows/arch.yml) and download+install `mozc-ut fcitx5-mozc-ut`
<!-- - install japanese
    - install `fcitx5-im`, choose all
    - install [mozc-ut](https://aur.archlinux.org/mozc-ut.git) (CPU warning)
    - install [fcitx5-mozc-ut](https://aur.archlinux.org/fcitx5-mozc-ut.git) (CPU warning) -->

- (optional) change boot order [🔗](https://askubuntu.com/a/1360740)
  ```bash
  cd /etc/grub.d
  sudo mv 30_os-prober 05_os-prober
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  ```
- (optional) remote folder
ftp://liuyulo3@individual.utoronto.ca

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

