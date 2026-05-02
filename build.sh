#!/bin/bash

DUMPFILE="$1"
echo $DUMPFILE

# 辞書作成
python mkjisyo.py $DUMPFILE

# 1,2文字の読みは削除する
# →日本語漢字変換のご動作を防ぐため
grep -v -P "^.{1,2}\t" jisyo.txt >jisyo2.txt

# 重複行削除
awk '!a[$0]++' jisyo2.txt >nodup.txt

# 作成日
DATE=$(date)

# sortをひらがな、カタカナ、漢字順にする
export LC_COLLATE=C

# mozc用辞書の作成
cat mozc_header.txt >mozc.txt
echo "# Created: $DATE" >>mozc.txt
cat nodup.txt | sort >>mozc.txt

# SKK用辞書の作成
cat skk_header.txt >skk.txt
echo ";; Created: $DATE" >>skk.txt
awk '{print $1 " /" $2 "/"}' nodup.txt | sort >>skk.txt

# MS-IME辞書の作成
cat msime_header.txt >msime.txt
echo "! Created: $DATE" >>msime.txt
cat nodup.txt | sort >>msime.txt
