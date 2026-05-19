#!/bin/bash

OUTDIR=output
if [ ! -e $OUTDIR ]; then
    mkdir $OUTDIR
fi

DUMPFILE="$1"
echo "DUMPFILE=$DUMPFILE"

# 作成日
DATE=$(TZ=Asia/Tokyo date "+%Y/%-m/%-d %H:%M:%S JST")
#DATE=$(LANG=C TZ=-9 date '+%a %b %d %H:%M:%S JST %Y')
echo $DATE

# sortをひらがな、カタカナ、漢字順にする
export LC_COLLATE=C

function create_jisyo_core() {
    DICNAME=$1
    DICFILE=$2
    CC=$3 # Comment Character
    BASE=$4
    DUMPFILE=$5

    echo "COMT=$COMT"

    echo "${CC} ${DICNAME}用Wikipedia人名辞書: $COMT" >$DICFILE
    echo "${CC} 生成元のデータ: $DUMPFILE" >>$DICFILE
    echo "${CC} 有効項目数: $LINE" >>$DICFILE
    echo "${CC} 読み, 語句, 品詞" >>$DICFILE
    echo "${CC} Created: $DATE" >>$DICFILE
    echo "" >>$DICFILE
    if [ "$DICNAME" = "SKK" ]; then
        awk '{print $1 " /" $2 "/"}' $BASE | sort >>$DICFILE
    else
        cat $BASE | sort >>$DICFILE
    fi
}

function create_jisyo() {
    BASE=$1
    TYPE=$2
    COMT="$3"

    LINE=$(wc -l $BASE | cut -f 1 -d ' ')

    # mozc用辞書の作成
    MOZC=$OUTDIR/mozc_${TYPE}.txt
    create_jisyo_core "mozc" $MOZC "#" $BASE $DUMPFILE

    # SKK用辞書の作成
    SKK=$OUTDIR/skk_${TYPE}.txt
    create_jisyo_core "SKK" $SKK ";;" $BASE $DUMPFILE

    # MS-IME辞書の作成
    MSIME=$OUTDIR/msime_${TYPE}.txt
    create_jisyo_core "MS-IME" $MSIME "!" $BASE $DUMPFILE
}

function main() {
    # 辞書作成
    python src/mkjisyo.py $DUMPFILE >$OUTDIR/jisyo.txt

    # 空行削除「
    grep -v "^$" $OUTDIR/jisyo.txt >$OUTDIR/jisyo2.txt

    # よみの入っていないおかしなデータは削除する
    grep -P -v "^\t" $OUTDIR/jisyo2.txt >$OUTDIR/jisyo3.txt

    # 重複行削除
    awk '!a[$0]++' $OUTDIR/jisyo3.txt >$OUTDIR/nodup_all.txt

    # 1,2文字の読みは削除する
    # →日本語漢字変換の誤動作を防ぐため
    grep -v -P "^.{1,2}\t" $OUTDIR/nodup_all.txt >$OUTDIR/nodup_over3.txt

    create_jisyo $OUTDIR/nodup_all.txt all "全て入り版"
    create_jisyo $OUTDIR/nodup_over3.txt over3 "１，２文字除外版"
}

main

# EOF
