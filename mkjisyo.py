#!/usr/bin/env python3
"""
Wikipediaダンプからmozc用人名辞書を作成する
"""

import re
import bz2
import sys
from pathlib import Path
from datetime import datetime
from lxml import etree


# -----------------------------------------------------
# RE_SEIMEI = re.compile(r"'''([一-龯々〆ヵヶ]+)\s+([一-龯々〆ヵヶ]+)'''（([ぁ-ゟ]+)\s+([ぁ-ゟ]+)")
# RE_TAN = re.compile(r"'''([一-龯々〆ヵヶ]+)'''（([ぁ-ゟ]+)")
RE_SEIMEI = re.compile(
    r"'''([一-龯ぁ-ゔァ-ヴー々]+)\s+([一-龯ぁ-ゔァ-ヴー々]+)'''（([ぁ-ん]+)\s+([ぁ-ん]+)"
)
RE_TAN = re.compile(r"'''([一-龯ぁ-ゔァ-ヴー々]+)'''（([ぁ-ん]+)")


# -------------------------------
def is_hiragana(s):
    # ひらがな（ぁ-ん）のみで構成されているか判定
    # ※長音符「ー」を含めたい場合は [ぁ-んー]+ に変更
    return bool(re.fullmatch(r"[ぁ-ん]+", s))


def proc_text(jisyo, text):
    """Wikipedia記事一ページ分のテキスト処理"""

    # ＜姓 名＞ 形式
    if m := RE_SEIMEI.search(text):
        sei_kanji, mei_kanji, sei_yomi, mei_yomi = m.groups()

        # Mozc辞書形式で出力
        if not is_hiragana(sei_kanji):
            jisyo.write(f"{sei_yomi}\t{sei_kanji}\t姓\n")
        if not is_hiragana(mei_kanji):
            jisyo.write(f"{mei_yomi}\t{mei_kanji}\t名\n")
        if not is_hiragana(sei_kanji + mei_kanji):
            jisyo.write(f"{sei_yomi}{mei_yomi}\t{sei_kanji}{mei_kanji}\t人名\n")
        return

    last500 = text[-500:]
    # ＜1単語＞ 形式
    if "人物" in last500:
        if m := RE_TAN.search(text):
            tan_kanji, tan_yomi = m.groups()

            # Mozc辞書形式で出力
            jisyo.write(f"{tan_yomi}\t{tan_kanji}\t人名\n")
            return


# -------------------------------


def is_kanji_1_to_6(s):
    """漢字1文字から6文字ならTrueを返す"""
    return bool(re.fullmatch(r"[一-龯]{1,6}", s))


def is_ja10(s):
    """日本語10文字以内ならTrue"""
    return bool(re.fullmatch(r"[一-龯ぁ-ゔァ-ヴー・]{1,10}", s))


def is_taisyo(title, text):
    """処理対象ならTrueを返す"""
    last500 = text[-500:]
    # return is_kanji_1_to_6(title)

    if is_ja10(title):
        if "人物" in last500:
            return True
    return False


def proc(jisyo, dumpfile):
    """メイン処理"""

    pagecount = 0

    ns_uri = None
    NS = None

    with bz2.open(dumpfile, "rb") as f:
        context = etree.iterparse(f, events=("start", "end"))

        for event, elem in context:
            # namespace detection
            if ns_uri is None and event == "start":
                if elem.tag.startswith("{"):
                    ns_uri = elem.tag.split("}")[0][1:]
                    NS = f"{{{ns_uri}}}"
                    print("NS=", NS)

                continue

            # page end
            if event == "end" and NS and elem.tag == NS + "page":
                title = elem.findtext(NS + "title", "")
                # ns = elem.findtext(NS + "ns", "")
                # text = elem.findtext(NS + "revision/text", "")
                text = elem.findtext(f"{NS}revision/{NS}text", "")

                # blist.write(f"pagetitle,{ns},{title}\n")
                if is_taisyo(title, text):
                    pagecount += 1

                    if (pagecount % 10000) == 0:
                        lognow("pagecount=" + str(pagecount))

                    if text:
                        proc_text(jisyo, text)

                # memory free (important)
                elem.clear()

                while elem.getprevious() is not None:
                    del elem.getparent()[0]


# -------------------------------


def lognow(msg):
    """log"""
    now = datetime.now().strftime("%Y/%m/%d %H:%M:%S")

    print(f"[{now}] {msg}")


# -------------------------------


def main():
    """main"""
    if len(sys.argv) < 2:
        print("Usage: python mkjisyo.py dumpfile1 dumpfile2 ...")
        sys.exit(1)

    dumpfiles = sys.argv[1:]
    jisyofile = "jisyo.txt"

    # if Path(jisyofile).exists():
    #    raise FileExistsError(f"File exists: {jisyofile}")

    lognow("mkjisyo start")
    lognow(f"jisyofile = {jisyofile}")

    # with bz2.open(jisyofile, "wt", encoding="utf-8") as jisyo:
    with open(jisyofile, "wt", encoding="utf-8") as jisyo:
        for dumpfile in dumpfiles:
            lognow(f"dumpfile = {dumpfile}")

            proc(jisyo, dumpfile)

    lognow("all done.")


# -------------------------------

if __name__ == "__main__":
    main()
