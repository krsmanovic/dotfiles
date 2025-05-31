#!/bin/bash

# vars
DESKTOP_USER=che
CREDENTIALS_DIR=/home/$DESKTOP_USER/.credentials
SMB_CREDENTIALS_FILE="smb"
SMB_SHARE_PATH="//smb.lan/cher"
SMB_MOUNT_DIR="/mnt/smb"
SMB_FSTAB_LINE="$SMB_SHARE_PATH $SMB_MOUNT_DIR cifs credentials=$CREDENTIALS_DIR/$SMB_CREDENTIALS_FILE 0 0"
NETWORK_MANAGER_CONFIG_OVERRIDES_PATH="/etc/NetworkManager/conf.d/99-overrides.conf"

# setup directories
mkdir -p $CREDENTIALS_DIR

# load common functions
source /home/$DESKTOP_USER/lib/sh/common.sh

# fix deafult postfix mess
log_message info "Fixing postfix default configuration..."
REAL_HOSTNAME=$(cat /etc/hostname)
sudo sed -i "s/^myhostname =.*/myhostname = $REAL_HOSTNAME/" /etc/postfix/main.cf

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
if grep "$SMB_FSTAB_LINE" /etc/fstab; then
    log_message info "SMB configuration is already present in fstab."
else
    log_message info "Adding SMB configuration to fstab..."
    sudo tee --append /etc/fstab > /dev/null <<< "$SMB_FSTAB_LINE"
fi

# network manager overrides
sudo tee $NETWORK_MANAGER_CONFIG_OVERRIDES_PATH > /dev/null << EOF
[connectivity]
# disable connectivity checks
interval=0
EOF
