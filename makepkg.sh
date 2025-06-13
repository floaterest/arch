set -ex

for v in "$@"; do
    git clone https://aur.archlinux.org/$v.git
    makepkg -D $v -si --noconfirm
done
