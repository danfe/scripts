#!/bin/sh

sleep 2

cd /tmp || exit 1

#file=$(date +ss_%s.png)
file=$(date +ss_%F_%T.png)

scrot -bs "${file}" && curl -s -F file1=@"${file}" ompldr.org/upload | \
grep -o -m 1 'http://ompldr.org/v[^<]*'
