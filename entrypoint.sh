#!/usr/bin/env bash

export INCOMING_LIST=/tmp/incoming.txt
export INCOMING_LIST_TMP=$INCOMING_LIST.tmp
export FILEBOT_PROCESSED=/tmp/amc.txt

if [ ! -d "/config/.filebot" ] && [ -f "${FILEBOT_LICENCE_FILE}" ]; then
    filebot --license "${FILEBOT_LICENCE_FILE}"
fi

while true; do
    sleep 63s

    find "$FILEBOT_INPUT_DIR" -type f > $INCOMING_LIST_TMP
    touch $INCOMING_LIST
    if ! cmp --silent $INCOMING_LIST $INCOMING_LIST_TMP; then
        filebot -script fn:amc \
            --output "${FILEBOT_OUTPUT_DIR}" \
            --action duplicate \
            -non-strict \
            --conflict auto \
            --def unsorted=y \
            --def movieFormat="{plex}" seriesFormat="{plex}" \
            --def excludeList=$FILEBOT_PROCESSED \
            "$FILEBOT_INPUT_DIR"
    fi

    mv $INCOMING_LIST_TMP $INCOMING_LIST
done
