#!/bin/bash

DUMPFILE="$1"
echo $DUMPFILE

# 辞書作成
python mkjisyo.py $DUMPFILE

# 重複行削除
awk '!a[$0]++' jisyo.txt | sort >mozc.txt

# SKK用辞書の作成
cat skk_header.txt >skk.txt
awk '{print $1 " /" $2 "/"}' mozc.txt | sort >>skk.txt

# MS-IME辞書の作成
cp mozc.txt msime.txt
