#!/bin/bash

# This tool reverts a mess nextcloud made at a certain date
DIR_SOURCE=$HOME/wip/thunder/thunderbird
WORKDIR="$(mktemp --directory --tmpdir=$HOME/tmp)"
FILE_LIST_TMP=$WORKDIR/file_list_tmp
FILE_LIST_UNIQ=$WORKDIR/file_list_uniq
FILE_LIST_DELETE=$WORKDIR/file_list_delete
FILE_LOG="$WORKDIR/unfuck.log"
DIR_OUTPUT="$WORKDIR/output"

# if common shell functions are loaded
if [ "$COMMON_BASH_LIB_LOADED" = "yes" ]; then
    logcmd () {
        log_message info "${@}"
        dd status=none oflag=append conv=notrunc of=$FILE_LOG <<< "$(stamp_time) INFO ${@}"
    }
else
    stamp_time () {
        TZ="Europe/Belgrade" date "+%Y-%m-%d %H:%M:%S"
    }
    logcmd () {
        echo $(stamp_time) INFO "${@}"
        dd status=none oflag=append conv=notrunc of=$FILE_LOG <<< "$(stamp_time) INFO ${@}"
    }
fi

if [[ $# -ne 1 ]]; then
    logcmd "Copy the script to the directory you want to untangle."
    logcmd "The script requires one argument in YYYY-MM-DD (ISO 8601 date) format."
    exit 1
fi

CUTOFF_DATE=$1

if (date -d $CUTOFF_DATE &> /dev/null) && [[ "$CUTOFF_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    logcmd "Cutoff date is $CUTOFF_DATE."
else
    logcmd "The script requires one argument in YYYY-MM-DD (ISO 8601 date) format."
    exit 1
fi

logcmd "Work directory is: $WORKDIR"

logcmd "Copying data to work directory. Source: $DIR_SOURCE; destination: $DIR_OUTPUT."
cp -r $DIR_SOURCE $DIR_OUTPUT
logcmd "Copying data completed."
# find $DIR_OUTPUT -type f -newermt $CUTOFF_DATE -delete
find $DIR_OUTPUT -type f -print > $FILE_LIST_TMP
cat $FILE_LIST_TMP | sed 's/\.v[0-9]*$//g' | sort | uniq > $FILE_LIST_UNIQ
EXPECTED_FILES=$(cat $FILE_LIST_UNIQ | wc -l)

NO_FILES=0
while IFS= read -r filepath; do
    # base variables
    filename=$(basename "$filepath")
    dirname=$(dirname "$filepath")
    unique_files=$(find "$dirname/" -name "$filename.*" -type f)
    number_of_files=$(find "$dirname/" -name "$filename.*" -type f | wc -l)

    # fix file timestamps
    for filename in "$unique_files"; do 
        unixtime=$(echo "${filename}" | sed -r 's/.*\.v([0-9]*)$/\1/')
        touchtime=$(date -d @$unixtime +'%Y%m%d%H%M.%S')
        touch -t ${touchtime} "${filename}"
    done

    logcmd "There are $number_of_files copies of $filename, in the directory $dirname"

    NO_FILES=$((NO_FILES + number_of_files))
    filename_candidates=$(find $DIR_OUTPUT -type f -newermt $CUTOFF_DATE -print)

    logcmd "Filename candidates are: $filename_candidates"
done < "$FILE_LIST_UNIQ"

logcmd "Expected number of files is $EXPECTED_FILES, and counted number of fils is $NO_FILES."
