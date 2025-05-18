#!/bin/bash

# vars
DESKTOP_USER=che
SMB_CONFIG_DIR="/home/$DESKTOP_USER/.config/smb"
SMB_CREDENTIALS_FILE=".credentials"
SMB_SHARE_PATH="//smb.lan/cher"
SMB_MOUNT_DIR="/mnt/smb"

# standardize stdout timestamp
stamp_time () {
    TZ="Europe/Belgrade" date "+%Y-%m-%d %H:%M:%S"
}

# configure logging
if logger -V &> /dev/null; then
    LOGGING_FACILITY="logger"
else
    LOGGING_FACILITY="fd"
fi

VALID_LOG_LEVEL_NAMES=(
    emerg
    alert
    crit
    err
    warning
    notice
    info
    debug
)

log_message () {
    local LOGGER_MESSAGE_LEVEL
    local LOGGER_MESSAGE
    local LOGGER_TIME

    LOGGER_TIME=$(stamp_time)
    LOGGER_MESSAGE_LEVEL=$1
    LOGGER_MESSAGE=$2

    TOLOWER_LOGGER_MESSAGE_LEVEL=$(echo $LOGGER_MESSAGE_LEVEL | awk '{print tolower($0)}')
    # validate log level
    if [ `echo "$VALID_LOG_LEVEL_NAMES" | grep -w -q "$TOLOWER_LOGGER_MESSAGE_LEVEL"` ]; then
        REAL_LOG_LEVEL="$TOLOWER_LOGGER_MESSAGE_LEVEL"
    else
        REAL_LOG_LEVEL="info"
    fi

    # print log message
    if [ $LOGGING_FACILITY == "logger" ]; then
        logger --priority "local7.$REAL_LOG_LEVEL" "$LOGGER_MESSAGE"
    else
        TOUPPER_REAL_LOG_LEVEL=$(echo $REAL_LOG_LEVEL | awk '{print toupper($0)}')
        echo "$LOGGER_TIME $TOUPPER_REAL_LOG_LEVEL $LOGGER_MESSAGE"
    fi
}

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
