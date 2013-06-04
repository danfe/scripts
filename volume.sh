#!/bin/bash
# Simple volume regulator for ALSA sound card driver.
#
# Mostly useable as binded to that extra rubber buttons on your keybo -
# application such as xbindkeys is needed.
# 
# Copyright (C) 2004, Kir Kolyshkin <kir@sacred.ru>.
# License terms: GNU General Public License.

MIXER="/usr/bin/amixer"
MIXER_GET="$MIXER sget"
MIXER_SET="$MIXER -q sset"
CHANNEL=Master
ATTVOL=6
TMPFILE=~/.volume

#
# You don't need to change anything below this line. Really.
#

PROG=`basename $0`

function usage()
{
	cat << EOF
$PROG v.0.9 - simple non-interactive audio volume regulator.
Usage: $PROG <command>, where command can be one of the following:
	u, +, up           - increase audio volume a bit
	d, -, down         - decrease audio volume a bit
	m, mute            - nicely (slowly) mute audio
	a, att             - almost mute (same as "ATT" on your car audio) 
	r, restore, unmute - unmute audio
	s, switch	   - mute or unmute
	h, help            - show this message
EOF
	exit $1
}

function getvol()
{
	local out=`$MIXER_GET $CHANNEL`
	MIN=`echo "$out" | awk '/Limits: Playback/ {print $3}'`
	MAX=`echo "$out" | awk '/Limits: Playback/ {print $5}'`
	LEFTVOL=`echo "$out" | awk '/Front Left: / {print $4}'`
	RIGHTVOL=`echo "$out" | awk '/Front Right: / {print $4}'`
	let TOTALVOL=LEFTVOL+RIGHTVOL
}

function calcvol()
{
	let LEFTVOL+=$1
	let RIGHTVOL+=$1
	# Normalize
	test $LEFTVOL -gt $MAX && LEFTVOL=$MAX
	test $RIGHTVOL -gt $MAX && RIGHTVOL=$MAX
	test $LEFTVOL -lt $MIN && LEFTVOL=$MIN
	test $RIGHTVOL -lt $MIN && RIGHTVOL=$MIN
	let TOTALVOL=LEFTVOL+RIGHTVOL
}

function setvol()
{
	$MIXER_SET $CHANNEL $LEFTVOL,$RIGHTVOL
}

function change()
{
	getvol
	calcvol $1
	setvol
}

function savevol()
{
	getvol
	echo "$CHANNEL $LEFTVOL $RIGHTVOL" > $TMPFILE
}

function loadvol()
{
	test -f $TMPFILE || return 1
	local vol=`cat $TMPFILE`
	local channel=`echo $vol | awk '{print $1}'`
	local leftvol=`echo $vol | awk '{print $2}'`
	local rightvol=`echo $vol | awk '{print $3}'`
	test -z "$channel" -o -z "$leftvol" -o -z "$rightvol" && return 1
	$MIXER_SET $channel $leftvol $rightvol
	echo -n > $TMPFILE
}

function mute()
{
	savevol
	while test $TOTALVOL -gt $1; do
		change -1
	done
	$MIXER_SET $CHANNEL off
}

function unmute()
{
	loadvol && $MIXER_SET $CHANNEL on
}

CMD=$1
case $CMD in
	u | + | up)
		change 1
		;;
	d | - | down)
		change -1
		;;
	m | mute)
		mute 0
		;;
	a | att)
		mute $ATTVOL
		;;
	r | restore | unmute)
		unmute
		;;
	s | switch)
		unmute || mute
		;;
	h | help)
		usage 0
		;;
	*)
		echo "$PROG error: Invalid command: $CMD" 1>&2
		usage 1
esac

# 
