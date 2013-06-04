#!/bin/sh

delay=600
pkill osd_cat

case $1 in
raise)
	vol=`mixer vol +5 | awk -F'[:.]' '{print $3}'`
	osd_cat -b percentage -p bottom -A center -o 32 -f 'sans 16' \
	-c green -d $delay -P $vol -T $vol%
	;;
lower)
	vol=`mixer vol -5 | awk -F'[:.]' '{print $3}'`
	osd_cat -b percentage -p bottom -A center -o 32 -f 'sans 16' \
	-c green -d $delay -P $vol -T $vol%
	;;
mute)
	if [ -f /tmp/.lastvol ]; then
		mixer vol $(cat /tmp/.lastvol)
		rm /tmp/.lastvol
		echo 音 | osd_cat -p bottom -f 'WenQuanYi Micro Hei 24' \
		-o -122 -c green -d $delay
	else
		mixer vol 0 | awk '{print $(NF-2)}' > /tmp/.lastvol
		echo 静 | osd_cat -p bottom -f 'WenQuanYi Micro Hei 24' \
		-o -122 -c red -d $delay
	fi
	;;
esac
