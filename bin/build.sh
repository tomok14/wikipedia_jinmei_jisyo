#!/bin/bash

# sortをひらがな、カタカナ、漢字順にする
export LC_COLLATE=C

OUTDIR=output
if [ ! -e $OUTDIR ]; then
    mkdir $OUTDIR
fi

# 作成日
DATE=$(TZ=Asia/Tokyo date "+%Y/%-m/%-d %H:%M:%S JST")
#DATE=$(LANG=C TZ=-9 date '+%a %b %d %H:%M:%S JST %Y')
echo "$DATE"

function create_jisyo_core() {
    dicname="$1"
    dicfile="$2"
    cc="$3" # Comment Character
    base="$4"
    dumpfile="$5"
    line="$6"
    comt="$7"

    echo "comt=$comt"

    # ヘッダ
    {
        echo "${cc} ${dicname}用Wikipedia人名辞書: $comt"
        echo "${cc} 生成元のデータ: $dumpfile"
        echo "${cc} 有効項目数: $line"
        echo "${cc} Created: $DATE"
        echo "${cc} 読み, 語句, 品詞"
        echo ""
    } >"$dicfile"

    # 本体
    if [ "$dicname" = "SKK" ]; then
        awk '{print $1 " /" $2 "/"}' "$base" | sort >>"$dicfile"
    else
        cat "$base" | sort >>"$dicfile"
    fi
}

function create_jisyo() {
    base="$1"
    type="$2"
    comt="$3"
    dumpfiles="$4"

    line=$(wc -l "$base" | cut -f 1 -d ' ')

    # mozc用辞書の作成
    mozc=$OUTDIR/mozc_${type}.txt
    create_jisyo_core "mozc" "$mozc" "#" "$base" "$dumpfiles" "$line" "$comt"

    # SKK用辞書の作成
    skk=$OUTDIR/skk_${type}.txt
    create_jisyo_core "SKK" "$skk" ";;" "$base" "$dumpfiles" "$line" "$comt"

    # MS-IME辞書の作成
    msime=$OUTDIR/msime_${type}.txt
    create_jisyo_core "MS-IME" "$msime" "!" "$base" "$dumpfiles" "$line" "$comt"

    # Gboard辞書の作成
    gboard=$OUTDIR/gboard_${type}.txt
    create_jisyo_core "Gboard" "$gboard" "!" "$base" "$dumpfiles" "$line" "$comt"
}

function main() {

    dumpfiles="$*"
    echo "dumpfiles=$dumpfiles"

    # 辞書作成
    python src/mkjisyo.py "$dumpfiles" >$OUTDIR/jisyo.txt

    # 空行削除
    grep -v "^$" $OUTDIR/jisyo.txt >$OUTDIR/jisyo2.txt

    # よみの入っていないおかしなデータは削除する
    grep -P -v "^\t" $OUTDIR/jisyo2.txt >$OUTDIR/jisyo3.txt

    # 重複行削除
    awk '!a[$0]++' $OUTDIR/jisyo3.txt >$OUTDIR/nodup_all.txt

    # 1,2文字の読みは削除する
    # →日本語漢字変換の誤動作を防ぐため
    grep -v -P "^.{1,2}\t" $OUTDIR/nodup_all.txt >$OUTDIR/nodup_over3.txt

    create_jisyo $OUTDIR/nodup_all.txt all "全て入り版" "$dumpfiles"
    create_jisyo $OUTDIR/nodup_over3.txt over3 "１，２文字除外版" "$dumpfiles"
}

main "$@"

# EOF
