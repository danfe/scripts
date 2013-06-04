#!/bin/sh

find -d . | while read f
do
	dn=${f%/*}
	bn=${f##*/}
	nbn=`echo ${bn} | iconv -t utf-8 -f koi8-r`
	test $? -eq 0 || continue
	test "${bn}" != . -a "${dn}/${bn}" != "${dn}/${nbn}" && mv "${dn}/${bn}" "${dn}/${nbn}"
done
