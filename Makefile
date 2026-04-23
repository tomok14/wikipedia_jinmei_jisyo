
all:
	echo hello

honban:
	wget https://dumps.wikimedia.your.org/jawiki/latest/jawiki-latest-pages-articles.xml.bz2
	./build.sh jawiki-latest-pages-articles.xml.bz2

test:
	./build.sh data/Wikipedia-20260410193938.xml.bz2
