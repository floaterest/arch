#!/usr/bin/env bash

set -e

function mkfs-sda(){
    # mkfs.fat -F32 /dev/sda1 # iff partition was not created for boot
    mkswap /dev/sda2
    swapon /dev/sda2
    mkfs.ext4 /dev/sda3
    mount /dev/sda3 /mnt
    mkdir -p /mnt/efi
    mount /dev/sda1 /mnt/efi
    lsblk
}

function mkfs-nvme(){
    # mkfs.fat -F32 /dev/nvme0n1p1 # iff partition was not created for boot
    mkswap /dev/nvme0n1p2
    mkfs.ext4 /dev/nvme0n1p3
    swapon /dev/nvme0n1p2
    mount /dev/nvme0n1p3 /mnt
    mkdir -p /mnt/efi
    mount /dev/nvme0n1p1 /mnt/efi
    lsblk
}

function pstrap(){
    pacstrap -K /mnt base base-devel linux linux-firmware grub efibootmgr git vi zsh
    perl -pi -e 's/#(?=en_US.UTF-8 UTF-8)//' /mnt/etc/locale.gen
    perl -pi -e 's/#(?=Color)//' /mnt/etc/pacman.conf
    perl -pi -e 's/# (?=%wheel ALL=\(ALL:ALL\) ALL)/Defaults insults\n/' /mnt/etc/sudoers
    genfstab -U /mnt > /mnt/etc/fstab
    printf "LANG=en_US.UTF-8\nLC_CTYPE=en_US.UTF-8\n" > /mnt/etc/locale.conf
    echo DESKTOP > /mnt/etc/hostname
}

function chroot(){
    locale-gen
    passwd
    useradd -m -G wheel -s /usr/bin/zsh u
    passwd u
    grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
}

function pacman_(){
    packages=(
        sddm firefox sof-firmware networkmanager dhcpcd iwd
	    # skip choices
	    noto-fonts noto-fonts-emoji pipewire-jack qt6-multimedia-gstreamer cronie
        # plasma
        bluedevil breeze breeze-gtk breeze-plymouth kactivitymanagerd kde-cli-tools kde-gtk-config kdecoration kdeplasma-addons kgamma kglobalacceld kinfocenter kmenuedit kpipewire kscreen kscreenlocker ksystemstats kwayland kwin layer-shell-qt libkscreen libksysguard libplasma plasma5support plasma-activities plasma-activities-stats plasma-browser-integration plasma-desktop plasma-disks plasma-firewall plasma-integration plasma-nm plasma-pa plasma-sdk plasma-systemmonitor plasma-thunderbolt plasma-workspace plymouth-kcm powerdevil print-manager sddm-kcm spectacle systemsettings wacomtablet xdg-desktop-portal-kde
        # kde-applications
        ark colord-kde dolphin dolphin-plugins ffmpegthumbs filelight francis gwenview isoimagewriter kalk kamera kamoso kate kcolorchooser kcron kdeconnect kdegraphics-thumbnailers kdenetwork-filesharing kdenlive kdialog keditbookmarks kget kjournald kmix kmousetool kmouth konsole ksystemlog kwave okular partitionmanager
        # other
        bat broot btop
        eza
        fd firewalld fzf fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt 
        krita
        lazygit less libreoffice-still libavif
        mpv
        neofetch neovide neovim
        obs-studio openssh
        pipewire-alsa
        qt5-imageformats
        ripgrep 
        sccache starship
        unrar unzip
        wl-clipboard
        zsh-autosuggestions zsh-completions zsh-syntax-highlighting
    )
    pacman -Syu ${packages[@]}
    systemctl enable sddm NetworkManager dhcpcd
}

function paru-bin(){
    git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
    cd /tmp/paru-bin
    makepkg -sir
}

function misc(){
    paru -Sa opentabletdriver
    systemctl --user daemon-reload
    systemctl --user enable opentabletdriver --now
    
    paru -Syu vscodium-bin stylua typstyle-bin rust-analyzer
    mkdir -p ~/.ssh
}

function select_opt() {
    select_option "$@" 1>&2
    echo $?
}

# https://unix.stackexchange.com/a/415155
function select_option() {
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "  $1 "; }
    print_selected()   { printf " $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }
    for opt; do printf "\n"; done
    local lastrow=`get_cursor_row`
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
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

function run(){
    read -p "`declare -f $1`"
    $1
}

options=(
    "  mkfs (sda) : efi on 1, swap on 2, /mnt on 3"
    "      (nvme) : efi on 1, swap on 2, /mnt/ on 3"
    "  pre-chroot : pacstrap, setup local, fsdab, hostname"
    " post-chroot : local-gen, passwd, grub-install"
    "             : install KDE packages"
    "post-install : install paru"
    "             : install more packages"
)
choice=`select_opt "${options[@]}"`

case $choice in
    0) run mkfs-sda;;
    1) run mkfs-nvme;;
    2) run pstrap;;
    3) run chroot;;
    4) run pacman_;;
    5) run paru-bin;;
    6) run misc;;
    *) echo "invalid option $REPLY";;
esac
