#!/bin/bash

# set -x
set -e

# This tool reverts a mess nextcloud made at a certain date

# change the source directory to match backup location
DIR_SOURCE=$HOME/wip/thunder/thunderbird
WORKDIR="$(mktemp --directory --tmpdir=$HOME/tmp)"
FILE_LIST_TMP=$WORKDIR/file_list_tmp
FILE_LIST_UNIQ=$WORKDIR/file_list_uniq
FILE_LIST_CANDIDATES=$WORKDIR/file_list_candidates
FILE_LIST_DELETE=$WORKDIR/file_list_delete
FILE_LOG="$WORKDIR/ops.log"
DIR_OUTPUT="$WORKDIR/output"
SIZE_DIR_SOURCE=$(du -hd0 $DIR_SOURCE | awk '{print $1}')

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
find $DIR_OUTPUT -type f -print > $FILE_LIST_TMP
cat $FILE_LIST_TMP | sed 's/\.v[0-9]*$//g' | sort | uniq > $FILE_LIST_UNIQ
EXPECTED_FILES=$(cat $FILE_LIST_UNIQ | wc -l)

logcmd "Starting the main loop..."
while IFS= read -r filepath; do
    # base variables
    filename=$(basename "$filepath")
    dirname=$(dirname "$filepath")
    cd "$dirname"
    unique_files=$(find . -type f -regextype posix-extended -regex ".*/$filename.v[0-9]{10}$")
    echo $unique_files > $WORKDIR/list_$(echo $filename | sed 's/\s/_/g')

    # fix file timestamps
    while IFS= read -r uniq_filename; do
        unixtime=$(echo "${uniq_filename}" | sed -r 's/.*\.v([0-9]*)$/\1/')
        touchtime=$(date -d @$unixtime +'%Y%m%d%H%M.%S')
        touch -t ${touchtime} "${uniq_filename}"
    done <<< "$unique_files"
    
    # find the latest file before the cutoff date; if there is none, use newer file
    filepath_candidate=$(find . -type f -regextype posix-extended -regex ".*/$filename.v[0-9]{10}$" -not -newermt $CUTOFF_DATE -print | sort | tail -1)
    if [ "$filepath_candidate" = "" ]; then
        filepath_candidate=$(find . -type f -regextype posix-extended -regex ".*/$filename.v[0-9]{10}$" -newermt $CUTOFF_DATE -print | sort | tail -1)
    fi
    filename_candidate=$(basename "$filepath_candidate")
    echo $filename_candidate >> $FILE_LIST_CANDIDATES

    # delete all the not needed file versions
    deleted_files=$(find . -type f ! -name "$filename_candidate" -regextype posix-extended -regex ".*/$filename.v[0-9]{10}$" -delete)

    # rename the file to expected original
    # logcmd "Renaming $filepath_candidate to $filepath."
    mv "$filepath_candidate" "$filepath"
done < "$FILE_LIST_UNIQ"

logcmd "Main loop is completed."
SIZE_DIR_OUTPUT=$(du -hd0 $DIR_OUTPUT | awk '{print $1}')

# print the report
logcmd "Original directory size was $SIZE_DIR_SOURCE, and after the cleanup it is $SIZE_DIR_OUTPUT."
