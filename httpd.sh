#!/bin/sh
#
# sh -c 'while :; do ~/bin/old-nc -lp 12345 -e ./httpd.sh ; sleep 1 ; done'

ROOT=/tmp

read foo FILE bar	# i.e., GET / HTTP/1.1
FILE=`echo ${FILE} | sed -E 's,\.\.,,g ; s,/+,/,g ; s,/$,,'`
file=`realpath ${ROOT}${FILE}`

if [ -d "${file}" ]
then
	echo "HTTP/1.1 200 OK"
	echo "Content-Type: text/html"
	echo
	ls "${file}" | while read f;
	do
		echo "<a href=\"${FILE}/${f}\">${f}</a><br>"
	done
else
	echo "HTTP/1.1 200 OK"
	echo "Content-Length: `stat -f %z ${file}`"
	echo
	cat "${file}"
fi
