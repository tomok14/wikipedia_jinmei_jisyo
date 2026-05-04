./bin/downarc_legacy.sh -a
FILE=$(ls jawiki*.bz2 | tail -1)
echo $FILE
./bin/build.sh $FILE
