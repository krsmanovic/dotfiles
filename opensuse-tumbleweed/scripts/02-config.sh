#!/bin/bash

# vars
DESKTOP_USER=che
SMB_CONFIG_DIR="/home/$DESKTOP_USER/.config/smb"
SMB_CREDENTIALS_FILE=".credentials"
SMB_SHARE_PATH="//smb.lan/cher"
SMB_MOUNT_DIR="/mnt/smb"
NETWORK_MANAGER_CONFIG_OVERRIDES_PATH="/etc/NetworkManager/conf.d/99-overrides.conf"

# load common functions
source /home/$DESKTOP_USER/lib/sh/common.sh

# fix deafult postfix mess
log_message info "Fixing postfix default configuration..."
REAL_HOSTNAME=$(cat /etc/hostname)
sudo sed -i "s/^myhostname =.*/myhostname = $REAL_HOSTNAME/" /etc/postfix/main.cf

# set smb share
log_message info "Setting up smb..."
sudo mkdir "$SMB_MOUNT_DIR"
mkdir -p "$SMB_CONFIG_DIR"
echo "Please create SMB credentials file at location $SMB_CONFIG_DIR/$SMB_CREDENTIALS_FILE."
read -p "Have you created SMB credentials file? y/n " -n 1 -r
echo
if [ $REPLY =~ ^[Yy]$ ]; then
    log_message info "SMB credentials file was created. Continuing..."
else
    log_message warning "No SMB credentials file was created. Exiting..."
    exit 0
fi
if [ -f $SMB_CONFIG_DIR/$SMB_CREDENTIALS_FILE ]; then
    SMB_USER="$(grep username $SMB_CONFIG_DIR/$SMB_CREDENTIALS_FILE | awk -F'=' '{print $2}')"
    SMB_PASSWORD="$(grep password $SMB_CONFIG_DIR/$SMB_CREDENTIALS_FILE | awk -F'=' '{print $2}')"
    if [ -z "${SMB_USER}" ] || [ -z "${SMB_PASSWORD}" ]; then
        log_message err "SMB credentials file must contain both username and password values. Exiting..."
        exit 1
    fi
else
    log_message err "No SMB credentials file found. Exiting..."
    exit 1
fi
echo "$SMB_SHARE_PATH $SMB_MOUNT_DIR cifs credentials=$SMB_CONFIG_DIR/$SMB_CREDENTIALS_FILE 0 0" | sudo tee --append /etc/fstab
echo "//smb.lan/cher /mnt/smb cifs credentials=/home/che/.config/smb/.credentials 0 0" | sudo tee --append /etc/fstab

# network manager overrides
sudo tee $NETWORK_MANAGER_CONFIG_OVERRIDES_PATH > /dev/null << EOF
[connectivity]
# disable connectivity checks
interval=0
EOF
