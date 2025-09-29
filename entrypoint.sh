#!/usr/bin/env bash

set -e

export INCOMING_LIST=/tmp/incoming.txt
export INCOMING_LIST_TMP=$INCOMING_LIST.tmp
export FILEBOT_PROCESSED=/config/amc.txt
export FILEBOT_ACTION=${FILEBOT_ACTION:-duplicate}

chown -R filebot:filebot /config
chown -R filebot:filebot "$FILEBOT_OUTPUT_DIR"

if [ ! -d "/config/.filebot" ] && [ -f "${FILEBOT_LICENCE_FILE}" ]; then
    gosu filebot filebot --license "${FILEBOT_LICENCE_FILE}"
fi

# Function to clean up the FILEBOT_PROCESSED file by removing non-existent files
cleanup_processed_file() {
    if [ -f "$FILEBOT_PROCESSED" ]; then
        local temp_file
        temp_file=$(mktemp)
        while IFS= read -r line; do
            # Skip empty lines and check if file exists
            if [ -n "$line" ] && [ -f "$line" ]; then
                echo "$line" >> "$temp_file"
            fi
        done < "$FILEBOT_PROCESSED"
        mv "$temp_file" "$FILEBOT_PROCESSED"
        echo "Cleaned up processed file list: $(wc -l < "$FILEBOT_PROCESSED") files remaining"
    fi
}

while true; do
    sleep 63s

    find "$FILEBOT_INPUT_DIR" -type f > $INCOMING_LIST_TMP
    touch $INCOMING_LIST
    if ! cmp --silent $INCOMING_LIST $INCOMING_LIST_TMP; then

        # wait for files to stop changing
        files=""
        while true; do
            echo "Waiting for files to stop changing..."
            new_files="$(find "$FILEBOT_INPUT_DIR" -type f -print0 | xargs -0 stat -c '%n %Y')"
            if [ "$files" != "$new_files" ]; then
                files="$new_files"
                sleep 5
            else
                break
            fi
        done

        gosu filebot filebot -script fn:amc \
            --output "${FILEBOT_OUTPUT_DIR}" \
            --action "$FILEBOT_ACTION" \
            -non-strict \
            --conflict auto \
            --def unsorted=y \
            --def movieFormat="{plex}" seriesFormat="{plex}" \
            --def excludeList=$FILEBOT_PROCESSED \
            --def ignore=incomplete/ \
            "$FILEBOT_INPUT_DIR"

        # Clean up the processed file list to remove non-existent files
        cleanup_processed_file

        if [ "$CLEANUP_AFTER_PROCESSING" = "true" ]; then
            find "$FILEBOT_INPUT_DIR" -type f -delete
        fi
    fi

    mv $INCOMING_LIST_TMP $INCOMING_LIST
done
