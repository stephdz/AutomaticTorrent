#!/bin/bash
OPEN_SUBTITLES_FOLDER=/var/lib/deluge/OpenSubtitles
OPEN_SUBTITLES_VERSION=1.0
OPEN_SUBTITLES_JAR="$OPEN_SUBTITLES_FOLDER/OpenSubtitles-$OPEN_SUBTITLES_VERSION.jar"

java -jar "$OPEN_SUBTITLES_JAR" $@