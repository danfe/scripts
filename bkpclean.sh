#!/bin/sh --posix
#
# $Id: bkpclean.sh,v 1.7 2007/12/14 23:55:02 danfe Exp $
#

dir=`dirname "$0"`
basedir=`readlink -f "${dir}"`
timestamp=`date +%F`
prefix=/usr/local/cvs/backup

curmonth=0
nextday=0

find_next()
{
	for ((day = $2; day < 31; day++)); do
		[ $day -lt 10 ] && td="0$day" || td=$day
		[ -f "${1/++/${td}}" -a $day -ge 15 ] && break
	done
	nextday=$day
}

clean()
{
	repo="$1"
	latestfile=$(basename `readlink -f "${basedir}/backup/${repo}-latest.tar.bz2"`)
	find . -type f -name "${repo}-*.tar.bz2" -exec basename '{}' \; | sort | while read bf; do
		month=$((10#${bf:((${#repo}+6)):2}))
		day=$((10#${bf:((${#repo}+9)):2}))
		tmp=${bf::((${#repo}+9))}++${bf:((${#repo}+11))}

		[ $month -ne $curmonth ] && nextday=$day && curmonth=$month

		# Calling find_next() outside the `if' clause does not work with
		# real file removes. *sigh*  Fix is probably needed.
		#
		if [ $day -eq $nextday -o "$bf" == "$latestfile" ]; then
			find_next "$tmp" "$day"
			echo "Preserve $bf"
		else
			find_next "$tmp" "$day"
			echo "Remove $bf"
			rm -f "$bf"
		fi
	done
}

if [ $# -lt 1 ]; then
	echo "Usage: `basename $0` dir..." 1>&2
	exit 0
fi

cd "${prefix}"
for repo in "$@"; do
	clean "${repo}"
done
