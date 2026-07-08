
all:
	echo hello

honban:
	./bin/down_build.sh

test:
	./bin/build.sh data/Wikipedia-20260708213825.xml

clean:
	rm output/*
