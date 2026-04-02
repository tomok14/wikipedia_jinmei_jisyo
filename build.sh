#!/usr/bin/bash

URL=https://dumps.wikimedia.your.org/jawiki/latest/jawiki-latest-pages-articles.xml.bz2
echo "$URL"
DUMPFILE=$(basename $URL)
echo "$DUMPFILE"
#exit 0

wget $URL
python mkjisyo.py $DUMPFILE
awk '!a[$0]++' jisyo.txt > out.txt
