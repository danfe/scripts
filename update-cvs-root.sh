#!/bin/sh

[ $# -eq 1 ] || ( echo "usage: $0 <CVS/Root>" >&2 ; exit 1 )

find . -type f -iregex '.*/CVS/Root' | ( while read f; do
	echo $1 > "$f"
	i=$((i+1))
done ; return $i )

echo $? files processed.
