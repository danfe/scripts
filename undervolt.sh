#!/bin/sh
#
# script to help you find stable vids when undervolting pentium m cpus
# for freebsd (7.2 and higher: depends on cpuctl(4))
#
# results for my pentium m 780:
#
#   2267 mhz: panic at vid = 25
#   1867 mhz: panic at vid = 15
#   1600 mhz: hang at vid = 11
#   1333 mhz: hang at vid = 5
#   1067 mhz: hang at vid = 0
#    800 mhz: test passed :)
#

get_est_levels()
{
	sysctl -n dev.est.0.freq_settings | sed 's,/[[:digit:]]*,,g'
}

simple_load()
{
	local i=0

	while :; do
		i=$((i + 1))
		test $i -gt 400000 && break
	done
}

ramp_down()
{
	local psv vid

	psv=$(($1 & 0xffff))
	vid=$((psv & 63))
	echo "current vid $vid, going down..."

	while [ $vid -gt 0 ]; do
		vid=$((vid - 1))
		psv=$(printf 0x%x $((psv - 1)))
		echo "=> trying vid $vid (psv $psv)"
		cpucontrol -m 0x199=$psv /dev/cpuctl0
		sleep 2
		simple_load
	done
}

test_freq()
{
	local msr

	echo ; echo "==> running tests for $1 mhz"
	sysctl dev.cpu.0.freq=$1
	msr=$(cpucontrol -m 0x198 /dev/cpuctl0 | cut -d\  -f4)
	ramp_down $msr
}

vchange_percent()
{
	local vid0 vstep

	# default values are for pentium m; adjust for your cpu
	vid0=700
	vstep=16

	echo $((100 - 100 * (vid0 + $1 * vstep) / (vid0 + $2 * vstep)))
}

set_freq_vid()
{
	local msr dif psv

	sysctl dev.cpu.0.freq=$1
	msr=$(cpucontrol -m 0x198 /dev/cpuctl0 | cut -d\  -f4)
	psv=$(printf 0x%x $((msr & 0xffc0 | $2)))
	dif=$(vchange_percent $2 $((msr & 63)))
	echo "==> setting vid $2 (psv $psv) for $1 mhz: $dif% undervolt"
	cpucontrol -m 0x199=$psv /dev/cpuctl0
}

if [ $(uname -s) != FreeBSD ]; then
	echo "this script is for FreeBSD, while you're running $(uname -s)"
	exit 1
fi

if [ $(id -u) -ne 0 ]; then
	echo "must be root to mess with cpu :)"
	exit 2
fi

pkill powerd
kldload cpuctl

# seemingly safe vid values (per super_pi and "make buildkernel" runs)
set_freq_vid 2267 29
#set_freq_vid 1867 18
#set_freq_vid 1600 12
#set_freq_vid 1333 7
#set_freq_vid 1067 2
#set_freq_vid 800 0
exit

echo -n "available est levels: "
get_est_levels				# 2267 1867 1600 1333 1067 800

sync ; sync ; sync
#test_freq 2267
#test_freq 1867
#test_freq 1600
#test_freq 1333
#test_freq 1067
#test_freq 800
