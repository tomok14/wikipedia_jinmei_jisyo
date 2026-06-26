#!/usr/bin/bash
# dumpサイトからダンプを全てダウンロードする
# 2026年以前の古い形式

AUTO=0
if [ "$1" = "-a" ]; then
    AUTO=1
fi

function get_latest_date() {
    TOPURL="$1"
    latest=$(curl -s "$TOPURL" | grep -E "href=\"[0-9]{8}\/\"" | tail -1 | sed -r 's/^.*([0-9]{4}[0-9]{2}[0-9]{2}).*$/\1/')
    echo "$latest"
}
function check_free_disk() {
    avail=$(/usr/bin/df --output="avail" . | grep -E "[0-9]+")
    human=$(numfmt --to=iec $((avail * 1024)))
    human="${human}B"
    echo "disk avail=$avail($human)"

    # 8Gは必須?
    if [ "$avail" -lt $((8 * 1024 * 1024)) ]; then
        echo "ERROR: no free space. avail=$human"
        exit 1
    fi
    return 0
}
function main() {
    # 空き容量チェック
    check_free_disk

    TOPURL="https://dumps.wikimedia.your.org/jawiki/"
    #TOPURL="https://dumps.wikimedia.org/jawiki/"
    latest=$(get_latest_date "$TOPURL")
    echo "latest=$latest"

    #https://dumps.wikimedia.org/jawiki/20260501/jawiki-20260501-pages-articles.xml.bz2
    arcdir="$TOPURL/$latest"
    LIST="jawiki-$latest-pages-articles.xml.bz2"
    echo "LIST=[$LIST]"

    # すでにdownload済かどうかチェック
    for i in $LIST; do
        if [ -f "$i" ]; then
            echo "Warn: file exist: $i"
        fi
    done

    # downloadするかどうかをユーザーに確認する
    if [ $AUTO -eq 0 ]; then
        read -rp "download? (y/N): " yn
        case "$yn" in
        [yY]*) echo "downloadします" ;;
        *)
            echo "abort"
            exit 1
            ;;
        esac
    fi

    # download
    for i in $LIST; do
        arcfile="$arcdir/$i"
        echo "Downloading $arcfile ..."
        wget -q "$arcfile"
    done

    ## bunzip2
    #for i in $LIST; do
    #    bunzip2 $i
    #done

}
main
