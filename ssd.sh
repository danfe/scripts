#!/bin/sh

# erase boundary in 512 byte blocks
# eg. for a 128KiB erase boundary:
# 131072 / 512 = 256
ERASEB=2048
TRACKB=63     # 63 sectors/track
TRACKB=16065  # 255 tracks/cylinder, 63 sectors/track (linux wants cylinder boundaries)
PARTB=$(( ${ERASEB} * ${TRACKB} ))

echo "enter byte offset of partition (append m/g for MiB/GiB)"
read boffset

case "" in
${boffset##*g})
	boffset=$(( ${boffset%*g} * 1073741824 ))
	;;
${boffset##*m})
	boffset=$(( ${boffset%*m} * 1048576 ))
	;;
esac

if [ -z "${boffset}" ]; then exit 1; fi

sectors=$(( ( ${boffset} - ( ${boffset} % 512 ) ) / 512 ))
npb=$(( ${sectors} / ${PARTB} ))
ssdlbahigh=$(( (${npb} + 1) * ${PARTB} ))
ssdlbalow=$(( ${npb} * ${PARTB} ))

echo
echo "Desired offset: ${boffset} bytes"
echo "Corrected offsets:"
echo "High: ${ssdlbahigh} blocks, $(( ${ssdlbahigh} / ${TRACKB} )) tracks @ \
${TRACKB} s/t ($(( ${ssdlbahigh} * 512 )) bytes)"
echo "Low: ${ssdlbalow} blocks, $(( ${ssdlbalow} / ${TRACKB} )) tracks @ \
${TRACKB} s/t ($(( ${ssdlbalow} * 512 )) bytes)"
