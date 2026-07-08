#!/usr/bin/env python3
"""
Wikipediaダンプからmozc用人名辞書を作成する
"""

import re
import regex
import bz2
import sys
from datetime import datetime
import lxml.etree as etree


# -----------------------------------------------------
RE_SEIMEI = regex.compile(
    r"'''([\p{Script=Han}\p{Hiragana}\p{Katakana}ー々]+)\s+"
    r"([\p{Script=Han}\p{Hiragana}\p{Katakana}ー々]+)'''"
    r"[^\(（]+"
    r"（([ぁ-んー]+)\s+([ぁ-んー]+)"
)

RE_TAN = regex.compile(
    r"'''([\p{Script=Han}\p{Hiragana}\p{Katakana}ー々]+)'''"
    r"（([ぁ-んー\s]+)"
)

# {{...}} テンプレート除去（名前と読みの間に挿入されるefn等への対応）
RE_STRIP_TEMPLATE = regex.compile(r"\{\{(?:[^{}]|(?R))*\}\}")


# -------------------------------
def is_hiragana(s):
    # ひらがな（ぁ-ん）のみで構成されているか判定
    # ※長音符「ー」を含めたい場合は [ぁ-んー]+ に変更
    return bool(re.fullmatch(r"[ぁ-ん]+", s))


def proc_text(text):
    """Wikipedia記事一ページ分のテキスト処理"""

    # {{...}} テンプレートを除去（efn, refn等が名前と読みの間にあるケースへの対応）
    text = RE_STRIP_TEMPLATE.sub("", text)

    # ＜姓 名＞ 形式
    if m := RE_SEIMEI.search(text):
        sei_kanji, mei_kanji, sei_yomi, mei_yomi = m.groups()

        # Mozc辞書形式で出力
        if not is_hiragana(sei_kanji):
            print(f"{sei_yomi}\t{sei_kanji}\t姓")
        if not is_hiragana(mei_kanji):
            print(f"{mei_yomi}\t{mei_kanji}\t名")
        if not is_hiragana(sei_kanji + mei_kanji):
            print(f"{sei_yomi}{mei_yomi}\t{sei_kanji}{mei_kanji}\t人名")
        return

    last500 = text[-500:]
    # ＜1単語＞ 形式
    if "人物" in last500:
        if m := RE_TAN.search(text):
            tan_kanji, tan_yomi = m.groups()
            # tan_yomi = tan_yomi.replace(" ", "")
            tan_yomi = re.sub(r"\s+", "", tan_yomi)

            if tan_yomi == "":
                return

            # Mozc辞書形式で出力
            print(f"{tan_yomi}\t{tan_kanji}\t人名")
            return


# -------------------------------


def is_kanji_1_to_6(s):
    """漢字1文字から6文字ならTrueを返す"""
    return bool(regex.fullmatch(r"[\p{Script=Han}々]{1,6}", s))


def is_ja10(s):
    """日本語10文字以内ならTrue"""
    return bool(
        regex.fullmatch(r"[\p{Script=Han}\p{Hiragana}\p{Katakana}ー・々]{1,10}", s)
    )


def is_taisyo(title, text):
    """処理対象ならTrueを返す"""

    # "篠原光 (アナウンサー)"のようなタイトルの括弧除去
    name = title.split(" (")[0] if " (" in title else title

    if is_ja10(name):
        last500 = text[-500:]
        if "人物" in last500:
            return True
    return False


def open_dumpfile(filename):
    """.xml と .xml.bz2 の両方に対応"""
    if filename.endswith(".bz2"):
        return bz2.open(filename, "rb")
    return open(filename, "rb")


def proc(dumpfile):
    """メイン処理"""

    pagecount = 0

    ns_uri = None
    NS = None

    # with bz2.open(dumpfile, "rb") as f:
    with open_dumpfile(dumpfile) as f:
        context = etree.iterparse(f, events=("start", "end"))

        for event, elem in context:
            # namespace detection
            if ns_uri is None and event == "start":
                if elem.tag.startswith("{"):
                    ns_uri = elem.tag.split("}")[0][1:]
                    NS = f"{{{ns_uri}}}"
                    lognow(f"{NS=}")

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
                        proc_text(text)

                # memory free (important)
                elem.clear()

                while elem.getprevious() is not None:
                    del elem.getparent()[0]


# -------------------------------


def lognow(msg):
    """log"""
    now = datetime.now().strftime("%Y/%m/%d %H:%M:%S")

    print(f"[{now}] {msg}", file=sys.stderr)


# -------------------------------


def main():
    """main"""
    if len(sys.argv) < 2:
        print("Usage: python mkjisyo.py dumpfile1 dumpfile2 ...", file=sys.stderr)
        sys.exit(1)

    dumpfiles = sys.argv[1:]
    jisyofile = "jisyo.txt"

    # if Path(jisyofile).exists():
    #    raise FileExistsError(f"File exists: {jisyofile}")

    lognow("mkjisyo start")
    lognow(f"jisyofile = {jisyofile}")
    lognow(f"dumpfiles = {dumpfiles}")

    # with bz2.open(jisyofile, "wt", encoding="utf-8") as jisyo:
    for dumpfile in dumpfiles:
        lognow(f"dumpfile = {dumpfile}")

        proc(dumpfile)

    lognow("all done.")


# -------------------------------

if __name__ == "__main__":
    main()
