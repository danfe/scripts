#!/bin/sh

http_decode()
{
	echo $* | awk 'BEGIN {
		FS = "";
	}

	function d2x(d) {
		hex = "0123456789ABCDEF";
		return (index(hex, d) - 1);
	}

	{
		for (i = 1; i <= NF; i++) {
			if ($i == "%") {
				a = ++i;
				b = ++i;
				printf("%c", d2x($a) * 16 + d2x($b));
			} else
				printf("%s", $i);
		}
	}'
}

find -d . | while read f
do
	dn=${f%/*}
	bn=${f##*/}
	nbn=`http_decode ${bn}`
	test "${bn}" != . -a "${dn}/${bn}" != "${dn}/${nbn}" && mv "${dn}/${bn}" "${dn}/${nbn}"
done
