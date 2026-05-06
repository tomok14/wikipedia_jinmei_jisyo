#!/bin/bash

OUTDIR=output

DUMPFILE="$1"
echo $DUMPFILE

# 作成日
DATE=$(TZ=Asia/Tokyo date "+%Y/%-m/%-d %H:%M:%S JST")
#DATE=$(LANG=C TZ=-9 date '+%a %b %d %H:%M:%S JST %Y')
echo $DATE

# sortをひらがな、カタカナ、漢字順にする
export LC_COLLATE=C

function create_jisyo() {
    BASE=$1
    TYPE=$2
    COMT="$3"

    MOZC=$OUTDIR/mozc_${TYPE}.txt

    # mozc用辞書の作成
    echo "# mozc用Wikipedia人名辞書: $COMT" >$MOZC
    echo "# 生成元のデータ: $DUMPFILE" >>$MOZC
    echo "# 読み, 語句, 品詞" >>$MOZC
    echo "# Created: $DATE" >>$MOZC
    cat $BASE | sort >>$MOZC

    SKK=$OUTDIR/skk_${TYPE}.txt

    # SKK用辞書の作成
    echo ";; -*- mode: fundamental; coding: utf-8 -*-" >$SKK
    echo ";; SKK用Wikipedia人名辞書: $COMT" >>$SKK
    echo ";; 生成元のデータ: $DUMPFILE" >>$SKK
    echo ";; Created: $DATE" >>$SKK
    awk '{print $1 " /" $2 "/"}' $BASE | sort >>$SKK

    MSIME=$OUTDIR/msime_${TYPE}.txt

    # MS-IME辞書の作成
    echo "! MS-IME用Wikipedia人名辞書: $COMT" >$MSIME
    echo "! 生成元のデータ: $DUMPFILE" >>$MSIME
    echo "! Created: $DATE" >>$MSIME
    cat $BASE | sort >>$MSIME
}

function main() {
    # 辞書作成
    python src/mkjisyo.py $DUMPFILE >$OUTDIR/jisyo.txt

    # よみの入っていないおかしなデータは削除する
    grep -P -v "^\t" $OUTDIR/jisyo.txt >$OUTDIR/jisyo2.txt

    # 重複行削除
    awk '!a[$0]++' $OUTDIR/jisyo2.txt >$OUTDIR/nodup_all.txt

    # 1,2文字の読みは削除する
    # →日本語漢字変換の誤動作を防ぐため
    grep -v -P "^.{1,2}\t" $OUTDIR/nodup_all.txt >$OUTDIR/nodup_over3.txt

    create_jisyo $OUTDIR/nodup_all.txt all "全て入り版"
    create_jisyo $OUTDIR/nodup_over3.txt over3 "１，２文字除外版"
}

main

# EOF
