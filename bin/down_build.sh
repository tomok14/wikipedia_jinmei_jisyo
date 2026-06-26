#!/usr/bin/bash

./bin/downarc_legacy.sh -a
#FILE=$(ls jawiki*.bz2 | tail -1)
shopt -s nullglob
files=(jawiki*.bz2)
file=${files[-1]}
echo "$file"
./bin/build.sh "$file"
