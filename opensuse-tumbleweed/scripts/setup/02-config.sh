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
KDE_THEME_NAME="com.github.vinceliuice.Graphite-dark"
SNAPPER_ROOT_CONFIG="/etc/snapper/configs/root"
SNAPPER_CLEANUP_TIMER_UNIT="/usr/lib/systemd/system/snapper-cleanup.timer"

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
    sudo dd status=none oflag=append conv=notrunc of=/etc/fstab <<< "$FSTAB_LINE_SMB"
    sudo mount -a
fi
if grep --quiet "$FSTAB_LINE_W" /etc/fstab; then
    log_message info "VM hosting disk configuration is already present in fstab."
else
    log_message info "Adding VM hosting disk configuration to fstab..."
    sudo dd status=none oflag=append conv=notrunc of=/etc/fstab <<< "$FSTAB_LINE_W"
    sudo mount -a
fi
if grep --quiet "$FSTAB_LINE_EDU" /etc/fstab; then
    log_message info "Edu partition configuration is already present in fstab."
else
    log_message info "Adding Edu partition configuration to fstab..."
    sudo dd status=none oflag=append conv=notrunc of=/etc/fstab <<< "$FSTAB_LINE_EDU"
    sudo mount -a
fi
if grep --quiet "$FSTAB_LINE_JUNKYARD" /etc/fstab; then
    log_message info "Junkyard partition configuration is already present in fstab."
else
    log_message info "Adding Junkyard partition configuration to fstab..."
    sudo dd status=none oflag=append conv=notrunc of=/etc/fstab <<< "$FSTAB_LINE_JUNKYARD"
    sudo mount -a
fi

# network overrides
sudo dd status=none of=$NETWORK_MANAGER_CONFIG_OVERRIDES_PATH << EOF
[connectivity]
# disable connectivity checks
#interval=0
EOF
IF_IPV6_DISABLE="# explicitly disable ipv6 on all interfaces"
for interface in $(ip -brief link | cut -d ' ' -f1); do
    IF_IPV6_DISABLE="$IF_IPV6_DISABLE
net.ipv6.conf.$interface.disable_ipv6 = 1"
done
sudo dd status=none of=$NETWORK_IPV6_SETTINGS << EOF
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
# https://freetype.org/freetype2/docs/hinting/text-rendering-general.html
echo 'FREETYPE_PROPERTIES="truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:no-stem-darkening=0"' | sudo dd status=none of=/etc/environment
sudo ln -s /usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/ || true
sudo ln -s /usr/share/fontconfig/conf.avail/10-autohint.conf /etc/fonts/conf.d/ || true
sudo ln -s /usr/share/fontconfig/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d/ || true

# snapper
sudo dd status=none of=$SNAPPER_CLEANUP_TIMER_UNIT << EOF
[Unit]
Description=Hourly Cleanup of Snapper Snapshots
Documentation=man:snapper(8) man:snapper-configs(5)

[Timer]
# OnBootSec=10m
# OnUnitActiveSec=1h
OnCalendar=Wed..Sun 04:00:00

[Install]
WantedBy=timers.target

EOF
sudo systemctl daemon-reload

sudo dd status=none of=$SNAPPER_ROOT_CONFIG << EOF
# subvolume to snapshot
SUBVOLUME="/"

# filesystem type
FSTYPE="btrfs"


# btrfs qgroup for space aware cleanup algorithms
QGROUP=""


# fraction or absolute size of the filesystems space the snapshots may use
SPACE_LIMIT="0.5"

# fraction or absolute size of the filesystems space that should be free
FREE_LIMIT="0.2"


# users and groups allowed to work with config
ALLOW_USERS=""
ALLOW_GROUPS=""

# sync users and groups from ALLOW_USERS and ALLOW_GROUPS to .snapshots
# directory
SYNC_ACL="no"


# start comparing pre- and post-snapshot in background after creating
# post-snapshot
BACKGROUND_COMPARISON="yes"


# run daily number cleanup
NUMBER_CLEANUP="yes"

# limit for number cleanup
NUMBER_MIN_AGE="3600"
NUMBER_LIMIT="50"
NUMBER_LIMIT_IMPORTANT="10"


# create hourly snapshots
TIMELINE_CREATE="no"

# cleanup hourly snapshots after some time
TIMELINE_CLEANUP="yes"

# limits for timeline cleanup
TIMELINE_MIN_AGE="3600"
TIMELINE_LIMIT_HOURLY="10"
TIMELINE_LIMIT_DAILY="10"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="10"
TIMELINE_LIMIT_QUARTERLY="0"
TIMELINE_LIMIT_YEARLY="10"


# cleanup empty pre-post-pairs
EMPTY_PRE_POST_CLEANUP="yes"

# limits for empty pre-post-pair cleanup
EMPTY_PRE_POST_MIN_AGE="3600"

EOF
