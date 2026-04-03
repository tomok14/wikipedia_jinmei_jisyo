#!/bin/bash

URL=https://dumps.wikimedia.your.org/jawiki/latest/jawiki-latest-pages-articles.xml.bz2
echo "$URL"
DUMPFILE=$(basename $URL)
echo "$DUMPFILE"
#exit 0

# ダンプが無いなら持ってくる
if [ ! -e $DUMPFILE ]; then
    wget $URL
fi

# 辞書が無いなら作成する
if [ ! -e jisyo.txt ]; then
    python mkjisyo.py $DUMPFILE
fi

# 重複行削除
awk '!a[$0]++' jisyo.txt > out.txt
