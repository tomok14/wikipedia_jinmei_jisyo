
all:
	echo hello

test:
	python3 ./mkjisyo.py test/Wikipedia-20260410193938.xml.bz2
	awk '!a[$0]++' jisyo.txt > out.txt
