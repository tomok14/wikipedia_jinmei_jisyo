#!/bin/bash

DUMPFILE="$1"
echo $DUMPFILE

# 作成日
DATE=$(date)

# sortをひらがな、カタカナ、漢字順にする
export LC_COLLATE=C

function create_jisyo() {
    BASE=$1
    TYPE=$2

    MOZC=mozc_${TYPE}.txt

    # mozc用辞書の作成
    cat mozc_header.txt >$MOZC
    echo "# Created: $DATE" >>$MOZC
    cat $BASE | sort >>$MOZC

    SKK=skk_${TYPE}.txt

    # SKK用辞書の作成
    cat skk_header.txt >$SKK
    echo ";; Created: $DATE" >>$SKK
    awk '{print $1 " /" $2 "/"}' $BASE | sort >>$SKK

    MSIME=msime_${TYPE}.txt

    # MS-IME辞書の作成
    cat msime_header.txt >$MSIME
    echo "! Created: $DATE" >>$MSIME
    cat $BASE | sort >>$MSIME
}

function main() {
    # 辞書作成
    python mkjisyo.py $DUMPFILE

    # 重複行削除
    awk '!a[$0]++' jisyo.txt >nodup_all.txt

    # 1,2文字の読みは削除する
    # →日本語漢字変換の誤動作を防ぐため
    grep -v -P "^.{1,2}\t" nodup_all.txt >nodup_over3.txt

    create_jisyo nodup_all.txt all
    create_jisyo nodup_over3.txt over3
}

main

# EOF
