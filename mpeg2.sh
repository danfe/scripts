#!/bin/sh

if [ $# -ne 2 ]
then
	echo "usage: $0 <input file> <output file>"
	exit 1
fi

#for i in *avi; do

mencoder -oac lavc -ovc lavc -of mpeg -mpegopts format=dvd:tsaf \
-vf scale=720:576,harddup -srate 48000 -af lavcresample=48000 \
-lavcopts vcodec=mpeg2video:vrc_buf_size=1835:vrc_maxrate=9800:vbitrate=4900:\
keyint=15:vstrict=0:acodec=ac3:abitrate=192:aspect=4/3 -ofps 25 \
-o "$2" "$1"

#done
