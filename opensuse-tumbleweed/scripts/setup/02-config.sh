#!/bin/bash

# vars
DESKTOP_USER=che
CREDENTIALS_DIR=/home/$DESKTOP_USER/.credentials
BASH_LIBRARY_COMMON=/home/$DESKTOP_USER/lib/sh/common.sh
SMB_CREDENTIALS_FILE="smb"
SMB_SHARE_PATH="//smb.lan/cher"
SMB_MOUNT_DIR="/mnt/smb"
FSTAB_LINE_SMB="$SMB_SHARE_PATH    $SMB_MOUNT_DIR                cifs   credentials=$CREDENTIALS_DIR/$SMB_CREDENTIALS_FILE,nofail 0 0"
FSTAB_LINE_W="UUID=9056009D56008666 /mnt/w              ntfs   defaults,nofail                0  0"
FSTAB_LINE_EDU="UUID=3006EF4D06EF12A0 /mnt/edu            ntfs   defaults,nofail                0  0"
FSTAB_LINE_JUNKYARD="UUID=B280FEB780FE80E1 /mnt/junkyard       ntfs   defaults,nofail                0  0"
NETWORK_MANAGER_CONFIG_OVERRIDES_PATH="/etc/NetworkManager/conf.d/99-overrides.conf"
NETWORK_IPV6_SETTINGS="/etc/sysctl.d/90-ipv6.conf"
KDE_LOOKANDFEEL_CFG_FILE_LOGOUT="/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/logout/Logout.qml"
GTK_SYSTEM_SOUNDS_OPTIONS="gtk-enable-event-sounds gtk-enable-input-feedback-sounds"
GTK_SETTINGS_FILES="/home/$DESKTOP_USER/.gtkrc-2.0 /home/$DESKTOP_USER/.config/gtk-3.0/settings.ini /home/$DESKTOP_USER/.config/gtk-4.0/settings.ini"
KDE_LOGOUT_TIME_SECONDS="5"
FC_DISCORD="/etc/fonts/conf.d/99-discord.conf"
FC_TELEGRAM="/etc/fonts/conf.d/98-telegram.conf"
XORG_CONFIG_MONITOR="/etc/X11/xorg.conf.d/90-monitor.conf"
KDE_THEME_NAME="com.github.vinceliuice.Graphite-dark"

# setup directories
mkdir -p $CREDENTIALS_DIR || true

# load common functions
if [ -f $BASH_LIBRARY_COMMON ]; then
    source $BASH_LIBRARY_COMMON
else
    echo "Failed to load common shell library."
    exit 1
fi

# fix deafult postfix mess
log_message info "Fixing postfix default configuration..."
REAL_HOSTNAME=$(cat /etc/hostname)
sudo sed -i "s/^myhostname =.*/myhostname = $REAL_HOSTNAME/" /etc/postfix/main.cf

# set user groups
if getent group libvirt &> /dev/null; then
  sudo usermod -aG libvirt $DESKTOP_USER
fi

# start libvirtd
if systemctl list-unit-files libvirtd.service &>/dev/null; then
    sudo systemctl enable libvirtd.service
    sudo systemctl start --now libvirtd.service
fi

# set smb share
log_message info "Setting up smb..."
if [ -f $CREDENTIALS_DIR/$SMB_CREDENTIALS_FILE ]; then
    SMB_USER="$(grep username $CREDENTIALS_DIR/$SMB_CREDENTIALS_FILE | awk -F'=' '{print $2}')"
    SMB_PASSWORD="$(grep password $CREDENTIALS_DIR/$SMB_CREDENTIALS_FILE | awk -F'=' '{print $2}')"
    if [ -z "${SMB_USER}" ] || [ -z "${SMB_PASSWORD}" ]; then
        log_message err "SMB credentials file must contain both username and password values. Exiting..."
        exit 1
    fi
else
    log_message err "No SMB credentials file found. Exiting..."
    exit 1
fi
if grep --quiet "$FSTAB_LINE_SMB" /etc/fstab; then
    log_message info "SMB configuration is already present in fstab."
else
    log_message info "Adding SMB configuration to fstab..."
    sudo tee --append /etc/fstab > /dev/null <<< "$FSTAB_LINE_SMB"
    sudo mount -a
fi
if grep --quiet "$FSTAB_LINE_W" /etc/fstab; then
    log_message info "VM hosting disk configuration is already present in fstab."
else
    log_message info "Adding VM hosting disk configuration to fstab..."
    sudo tee --append /etc/fstab > /dev/null <<< "$FSTAB_LINE_W"
    sudo mount -a
fi
if grep --quiet "$FSTAB_LINE_EDU" /etc/fstab; then
    log_message info "Edu partition configuration is already present in fstab."
else
    log_message info "Adding Edu partition configuration to fstab..."
    sudo tee --append /etc/fstab > /dev/null <<< "$FSTAB_LINE_EDU"
    sudo mount -a
fi
if grep --quiet "$FSTAB_LINE_JUNKYARD" /etc/fstab; then
    log_message info "Junkyard partition configuration is already present in fstab."
else
    log_message info "Adding Junkyard partition configuration to fstab..."
    sudo tee --append /etc/fstab > /dev/null <<< "$FSTAB_LINE_JUNKYARD"
    sudo mount -a
fi

# network overrides
sudo tee $NETWORK_MANAGER_CONFIG_OVERRIDES_PATH > /dev/null << EOF
[connectivity]
# disable connectivity checks
#interval=0
EOF
IF_IPV6_DISABLE="# explicitly disable ipv6 on all interfaces"
for interface in $(ip -brief link | cut -d ' ' -f1); do
    IF_IPV6_DISABLE="$IF_IPV6_DISABLE
net.ipv6.conf.$interface.disable_ipv6 = 1"
done
sudo tee $NETWORK_IPV6_SETTINGS > /dev/null << EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
$IF_IPV6_DISABLE
EOF
sudo sysctl --system

# look and feel
if lookandfeeltool --list | grep --quiet $KDE_THEME_NAME; then
    log_message info "Setting global KDE theme..."
    lookandfeeltool --apply $KDE_THEME_NAME
fi
# if stat /usr/libexec/plasma-changeicons &> /dev/null; then
#     log_message info "Setting DarK icon theme..."
#     /usr/libexec/plasma-changeicons DarK-svg
# else
#     log_message err "Setting DarK icon theme failed. No Plasma changeicons tool found."
# fi
if [ -f $KDE_LOOKANDFEEL_CFG_FILE_LOGOUT ]; then
    sudo sed -Ei "s/(property real timeout\:).*/\1 $KDE_LOGOUT_TIME_SECONDS/" $KDE_LOOKANDFEEL_CFG_FILE_LOGOUT
    log_message info "KDE logout time was set to $KDE_LOGOUT_TIME_SECONDS seconds."
else
    log_message err "KDE configuration file $KDE_LOOKANDFEEL_CFG_FILE_LOGOUT could not be found..."
fi

for gtk_settings_file in $GTK_SETTINGS_FILES; do
    if [ -f "$gtk_settings_file" ]; then
        for gtk_option in $GTK_SYSTEM_SOUNDS_OPTIONS; do
            if grep --word-regexp --quiet $gtk_option "$gtk_settings_file"; then
                sed -i "s/\($gtk_option\).*/\1=false/" "$gtk_settings_file"
                log_message info "GTK option $gtk_option is updated in file $gtk_settings_file."
            else
                echo "$gtk_option=false" >> "$gtk_settings_file"
                log_message info "GTK option $gtk_option is created in file $gtk_settings_file."
            fi
        done
    else
        log_message err "$gtk_settings_file not found."
    fi
done

# fonts
sudo tee $FC_DISCORD > /dev/null << "EOF"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
    <match>
        <test name="prgname">
            <string>Discord</string>
        </test>
        <edit name="hintstyle" mode="assign">
            <const>hintfull</const>
        </edit>
        <edit name="lcdfilter" mode="assign">
            <const>lcddefault</const>
        </edit>
    </match>
    <match>
        <test name="prgname">
            <string>com.discordapp.Discord</string>
        </test>
        <edit name="hintstyle" mode="assign">
            <const>hintfull</const>
        </edit>
        <edit name="lcdfilter" mode="assign">
            <const>lcddefault</const>
        </edit>
    </match>
</fontconfig>
EOF
sudo tee $FC_TELEGRAM > /dev/null << "EOF"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
    <match>
        <test name="prgname">
            <string>Telegram</string>
        </test>
        <edit name="hintstyle" mode="assign">
            <const>hintmedium</const>
        </edit>
        <edit name="lcdfilter" mode="assign">
            <const>lcddefault</const>
        </edit>
    </match>
    <match>
        <test name="prgname">
            <string>org.telegram.desktop</string>
        </test>
        <edit name="hintstyle" mode="assign">
            <const>hintmedium</const>
        </edit>
        <edit name="lcdfilter" mode="assign">
            <const>lcddefault</const>
        </edit>
    </match>
</fontconfig>
EOF

# fix monitor dpi
# https://wiki.archlinux.org/title/Xorg#Display_size_and_DPI
# get real monitor geometry
# edid-decode -o xml  < /sys/class/drm/card1-DP-3/edid
# ...
#   Detailed Timing Descriptors:
#     DTD 1:  1920x1080   60.000000 Hz  16:9     67.500 kHz    148.500000 MHz (527 mm x 297 mm)
# ...
# get display id
# xrandr --prop | grep ' connected'
# DP-4 connected primary 1920x1080+0+0 (normal left inverted right x axis y axis) 527mm x 297mm
sudo tee $XORG_CONFIG_MONITOR > /dev/null << "EOF"
Section "Monitor"
    Identifier             "DP-4"
    DisplaySize             527 297
EndSection
EOF

# convert opensuse logo from svg to raw image format for fastfetch
# i have only changed green tone; original was fetched from https://en.opensuse.org/images/6/6c/OpenSUSE-hellcp.svg
# kitten icat -n --align=left --transfer-mode=stream /home/$DESKTOP_USER/.config/fastfetch/images/chameleon-kitty.svg > /home/$DESKTOP_USER/.config/fastfetch/images/chameleon-kitty.bin
