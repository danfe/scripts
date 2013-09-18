#!/bin/sh

find --version 2>/dev/null >&2 && _opt=". -regextype egrep" || _opt="-E ."

find $_opt -type f -iregex '.*\.(h|c|cc|cpp)' | while read f
do
	if [ "`tail -c 1 "$f"`" ]; then
		echo "$f lacks newline at EOF, fixing"
		echo >> "$f"
	fi
done
