
all:
	echo hello

honban:
	./bin/down_build.sh

test:
	./bin/build.sh data/Wikipedia-20260410193938.xml.bz2
