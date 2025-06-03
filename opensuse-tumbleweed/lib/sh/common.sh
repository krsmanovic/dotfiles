#!/bin/bash

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

    TOUPPER_REAL_LOG_LEVEL=$(echo $REAL_LOG_LEVEL | awk '{print toupper($0)}')

    # print log message
    if [ $LOGGING_FACILITY == "logger" ]; then
        logger --priority "local7.$REAL_LOG_LEVEL" "$LOGGER_MESSAGE"
        if [ "$REAL_LOG_LEVEL" != "info" ]; then
            echo "$LOGGER_TIME $TOUPPER_REAL_LOG_LEVEL $LOGGER_MESSAGE"
        fi
    else
        echo "$LOGGER_TIME $TOUPPER_REAL_LOG_LEVEL $LOGGER_MESSAGE"
    fi
}
