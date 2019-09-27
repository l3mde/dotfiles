#!/usr/bin/env sh

NEW_USER_NAME="moody"
NEW_USER_COMMENT="Andi"

set -x

function provision_init {
    ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
    cp -n /etc/locale.gen /etc/locale.gen.l3m
    echo """de_DE.UTF-8 UTF-8
en_US.UTF-8 UTF-8""" > /etc/locale.gen
    locale-gen
    echo """LANG=en_US.UTF-8""" > /etc/locale.conf
    echo """KEYMAP=de-latin1-nodeadkeys""" > /etc/vconsole.conf
    echo """andi-laptop""" > /etc/hostname
    bootctl install
    echo """title ArchLinux (ZEN)
linux /vmlinuz-linux-zen
initrd /initramfs-linux-zen.img
options ...""" > /boot/loader/entries/arch-zen.conf
    blkid >> /boot/loader/entries/arch-zen.conf
    echo """default arch-zen""" > /boot/loader/loader.conf
    cp -n /etc/mkinitcpio.conf /etc/mkinitcpio.conf.l3m
    echo """MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev keyboard keymap autodetect modconf block encrypt lvm2 resume filesystems fsck)""" > /etc/mkinitcpio.conf
}

function provision_packages {
    pacman -S base-devel vim htop tmux bash bash-completion zsh git go xorg lightdm-gtk-greeter lightdm-gtk-greeter-settings firefox i3 py3status noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra networkmanager docker rofi autojump linux linux-headers linux-zen linux-zen-headers nextcloud-client gnome-keyring libgnome-keyring seahorse openssh network-manager-applet bluez blueman xss-lock python-pytz python-tzlocal xautolock redshift iw gtk2 lxappearance-gtk3 arc-solid-gtk-theme gtk-engine-murrine papirus-icon-theme ttf-font-awesome thunar gvfs tumbler thunar-volman thunar-archive-plugin thunar-media-tags-plugin ntfs-3g gptfdisk dosfstools gvfs-afc gvfs-smb gvfs-gphoto2 gvfs-mtp gvfs-goa gvfs-nfs gvfs-google ffmpegthumbnailer poppler-glib libgsf libopenraw freetype2 xarchiver gst-plugins-good gst-plugins-bad gst-libav gst-plugins-ugly poppler-data arj binutils bzip2 cpio gzip lha lrzip lz4 lzip lzop p7zip tar unarj unrar unzip xz zip zstd libdvdcss libbluray compton viewnior nitrogen pulseaudio pavucontrol paprefs pasystray pulseaudio-alsa pulseaudio-bluetooth xdg-user-dirs-gtk alsa-utils alsa-tools lxterminal autorandr
    systemctl enable lightdm.service
    systemctl enable NetworkManager.service
    systemctl enable docker.service
    systemctl enable bluetooth.service
    systemctl enable fstrim.timer
}

function provision_user {
    useradd -m -c "$NEW_USER_COMMENT" -b /home "$NEW_USER_NAME"
    gpasswd -a "$NEW_USER_NAME" wheel
    gpasswd -a "$NEW_USER_NAME" video
    echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
    chsh -s /usr/bin/zsh "$NEW_USER_NAME"
    su "$NEW_USER_NAME" -c """git clone https://github.com/l3mde/dotfiles.git ~/sources/l3mde/dotfiles
(cd ~/sources/l3mde/dotfiles && git pull)
(cd ~/sources/l3mde/dotfiles && ./dotdrop -p default install)"""
}

function provision_yay {
    TEMP_DIR_yay="`su "$NEW_USER_NAME" -c """mktemp -d"""`"
    su "$NEW_USER_NAME" -c """cd '$TEMP_DIR_yay'
curl -L https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz | tar -xvz
cd yay
makepkg"""
    pacman --noconfirm -U "$TEMP_DIR_yay/yay/yay"*".pkg.tar.xz"
    rm -rf "$TEMP_DIR_yay"
}

function provision_sys {
    echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
    echo '''ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"''' > /etc/udev/rules.d/backlight.rules
    echo '''QT_QPA_PLATFORMTHEME=gtk2
DESKTOP_SESSION=gnome''' > /etc/environment
    echo '''Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "ClickMethod" "clickfinger"
EndSection''' > /etc/X11/xorg.conf.d/30-touchpad.conf

    echo '''[agent]
whitelist=geoclue-demo-agent;gnome-shell;io.elementary.desktop.agent-geoclue2
[network-nmea]
enable=true
[3g]
enable=true
[cdma]
enable=true
[modem-gps]
enable=true
[wifi]
enable=true
url=https://location.services.mozilla.com/v1/geolocate?key=geoclue
submit-data=false
submission-url=https://location.services.mozilla.com/v1/submit?key=geoclue
submission-nick=geoclue
[firefox]
allowed=true
system=false
users=
[redshift]
allowed=true
system=false
users=''' > /etc/geoclue/geoclue.conf
    echo '''[greeter]
theme-name = Arc-Darker-solid
icon-theme-name = Papirus-Dark
font-name = Noto Sans 10
background = #3465a4
user-background = false
hide-user-image = true
screensaver-timeout = 30
clock-format =   %Y-%m-%d %H:%M:%S      %H:%M:%S
indicators = ~spacer;~clock;~spacer;~power''' > /etc/lightdm/lightdm-gtk-greeter.conf
    localectl --no-convert set-x11-keymap de pc105 nodeadkeys
}

case $1 in
    step)
        provision_$2
    ;;
    all)
        provision_init
        provision_packages
        provision_user
        provision_sys
        provision_yay
    ;;
    *)
        echo "Nothing"
    ;;
esac


echo """!!! TODO !!!
* passwd
* passwd moody
* edit /boot/loader/entries/arch-zen.conf"""
