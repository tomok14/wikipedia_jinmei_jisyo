#!/bin/bash

DUMPFILE="$1"
echo $DUMPFILE

# 辞書作成
python mkjisyo.py $DUMPFILE

# 重複行削除
awk '!a[$0]++' jisyo.txt > out.txt
