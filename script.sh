#!/usr/bin/env bash
set -e

function writeln() {
    echo "$(tput bold)$1$(tput sgr0)"
}

function mkfs-nvme() {
    # mkfs.fat -F32 /dev/nvme0n1p1 # if partition was not created for boot
    mkswap /dev/nvme0n1p2
    mkfs.ext4 /dev/nvme0n1p3
    swapon /dev/nvme0n1p2
    mount /dev/nvme0n1p3 /mnt
    mkdir -p /mnt/efi
    mount /dev/nvme0n1p1 /mnt/efi
    mkdir -p /mnt/mnt # to mount backup HDD
    lsblk

    writeln "Please run prechroot"
}

function prechroot() {
    echo -n "Enter hostname: "
    read hostname
    pacstrap -K /mnt base base-devel linux linux-firmware grub efibootmgr git vi zsh os-prober # in case you need to dual boot
    perl -pi -e 's/#(?=en_US.UTF-8 UTF-8)//' /mnt/etc/locale.gen
    perl -pi -e 's/#(?=Color)//' /mnt/etc/pacman.conf
    perl -pi -e 's/# (?=%wheel ALL=\(ALL:ALL\) ALL)/Defaults insults\n/' /mnt/etc/sudoers
    genfstab -U /mnt >/mnt/etc/fstab
    printf "LANG=en_US.UTF-8\nLC_CTYPE=en_US.UTF-8\n" >/mnt/etc/locale.conf
    echo $hostname >/mnt/etc/hostname

    writeln "Please arch-chroot /mnt, mount backup, then run postchroot"
}

function postchroot() {
    locale-gen
    printf "\nEnter password for root\n"
    passwd
    useradd -m -G wheel -s /usr/bin/zsh u
    printf "\nEnter password for u\n"
    passwd u
    grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
    # install grub theme
    git clone --depth 1 https://github.com/vinceliuice/grub2-themes.git /tmp/grub2-themes
    /tmp/grub2-themes/install.sh -t stylish

    writeln "Please su u, restore backup (put *.zst in /tmp), then run setup"
}

function setup() {
    packages=(
        # niri
        niri xwayland-satellite
        xdg-desktop-portal-gnome xdg-desktop-portal-gtk alacritty
        fuzzel swaylock cliphist
        # sound & network
        sof-firmware wireplumber qt6-multimedia-ffmpeg
        pipewire pipewire-audio pipewire-jack pipewire-pulse pipewire-alsa
        networkmanager dhcpcd iwd bluez
        # login
        # greetd greetd-regreet
        # GUI
        firefox
        breeze breeze-gtk
        noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-roboto
        # kde applications
        # ark dolphin dolphin-plugins
        ffmpegthumbs filelight
        gwenview isoimagewriter
        kdeconnect # kdenlive
        okular partitionmanager
        qt5-imageformats
        # other applications
        alacritty bat broot btop code discord eza fd firewalld fzf
        fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt
        fprintd fuse2 gimp
        keepassxc
        lazygit less libreoffice-still libavif
        mpv man-db
        neovide neovim
        obs-studio openssh obsidian
        ripgrep rsync
        sccache starship sshfs
        unrar unzip uv
        zsh-autosuggestions zsh-completions zsh-syntax-highlighting
        # programming languages
        rustup typst typstyle shfmt stylua rust-analyzer tinymist
        tree-sitter-cli ruff
    )
    sudo pacman -Syu --noconfirm ${packages[@]}
    # sudo pacman -U /tmp/*.zst
    sudo systemctl enable NetworkManager dhcpcd # greetd
    sudo timedatectl set-timezone 'Asia/Tokyo'  # timedatectl list-timezones
    systemctl --user daemon-reload
    systemctl --user enable opentabletdriver
    # install darkly-gtk
    gsettings set org.gnome.desktop.interface gtk-theme Darkly
    writeln "Please exit from chroot, then reboot"
}

function select_opt() {
    select_option "$@" 1>&2
    echo $?
}

# https://unix.stackexchange.com/a/415155
function select_option() {
    ESC=$(printf "\033")
    cursor_blink_on() { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to() { printf "$ESC[$1;${2:-1}H"; }
    print_option() { printf "  $1 "; }
    print_selected() { printf " $ESC[7m $1 $ESC[27m"; }
    get_cursor_row() {
        IFS=';' read -sdR -p $'\E[6n' ROW COL
        echo ${ROW#*[}
    }
    key_input() {
        read -s -n3 key 2>/dev/null >&2
        if [[ $key = $ESC[A ]]; then echo up; fi
        if [[ $key = $ESC[B ]]; then echo down; fi
        if [[ $key = "" ]]; then echo enter; fi
    }
    for opt; do printf "\n"; done
    local lastrow=$(get_cursor_row)
    local startrow=$(($lastrow - $#))
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case $(key_input) in
        enter) break ;;
        up)
            ((selected--))
            if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi
            ;;
        down)
            ((selected++))
            if [ $selected -ge $# ]; then selected=0; fi
            ;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

function run() {
    read -p "$(declare -f $1)"
    $1
}

options=(
    " mkfs (nvme) : efi on 1, swap on 2, /mnt/ on 3"
    "  pre-chroot : pacstrap, setup local, fsdab, hostname"
    " post-chroot : local-gen, passwd, grub-install"
    "       setup : install and setup window manager"
)
choice=$(select_opt "${options[@]}")

case $choice in
0) run mkfs-nvme ;;
1) run prechroot ;;
2) run postchroot ;;
3) run setup ;;
*) echo "invalid option $REPLY" ;;
esac
