#!/bin/sh

# to rip: cdparanoia -pB

# $1 - track no
# $2 - title
# $3 - artist (if needed)

prefix=.

#lame -r --preset standard --tt "$2" --ta "Грозовой перевал" --tl "Песни разных годов и из разных альбомов" --ty 1995 --tc "Ripped by DAN Fe" --tn "$1" --tg 10 --add-id3v2 --id3v2-only track"$1".cdda.raw "$1 - $2.mp3"

lame -r --preset standard --tt "$2" --ta "Комбинация" --tl "Русские девочки" --ty 2004 --tc "Ripped by DAN Fe" --tn "$1" --tg 13 --add-id3v2 --id3v2-only ${prefix}/track"$1".cdda.raw "$1 - $2.mp3"

#lame -r --preset standard --tt "$2" --ta "Dave Gahan" --tl "Hourglass" --ty 2007 --tc "Ripped by DAN Fe" --tn "$1" --tg 20 --add-id3v2 track"$1".cdda.raw "$1 - $2.mp3"
