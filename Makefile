
all:
	echo hello

honban:
	./down_build.sh

test:
	./build.sh data/Wikipedia-20260410193938.xml.bz2
