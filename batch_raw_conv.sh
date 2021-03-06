#!/bin/bash
#
# convertraw
# Convert from PEF/DNG to JPG
#
# Copyright 2009 Clarke A. Wixon
#
# This work is licensed under the Creative Commons
# Attribution-Noncommercial-Share Alike 3.0 Unported License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/
# or send a letter to Creative Commons, 171 Second Street, Suite 300,
# San Francisco, California, 94105, USA.
#

comment="Autoconversion script rev. 2009-06-26"
gamma="2.2"
contrast="5.0x35%"
lc="0x40.0+0.2+0.0"
saturation=105
jpgqual=85
isolevel=( 0 100 200 400 800 1600 3200 6400 )
nrlevel=( 25 25 50 100 200 400 800 1600 ) # change this to alter dcraw noise-reduction levels
sharplevel=( 0.7500 0.7500 0.5000 0.2500 0.0000 0.0000 0.0000 0.0000 ) # change this to alter imagemagick sharpening amounts

shopt -s nullglob # if there are no matching files, don't try to process the glob as an actual filename

if [ -z "$1" ]
then
  infiles="*.PEF *.DNG"
else
  infiles="$@"
fi

echo "Converting $infiles . . ."

for rawname in $infiles
do

# set filenames

  if [[ "$rawname" =~ ".PEF" ]]
  then
    basename="${rawname%.PEF}"
  else
    basename="${rawname%.DNG}"
  fi
  tifname="${basename}.tif"
  pefexif="${basename}.exv"
  jpegname="${basename}-batch.jpg"
  jpgexif="${jpegname%.jpg}.exv"

  if [ -f $rawname ]
  then

    isoval=$( exiv2 print "$rawname" | grep "ISO speed" | awk '{print $4}' )

    if (( $isoval >= 6400 ))
    then
      denoise=${nrlevel[7]} # max value
      unsharp=${sharplevel[7]} # max value
    else
      denoise=${nrlevel[0]} # minimum default value; shouldn't be needed
      unsharp=${sharplevel[7]} # minimum default value; shouldn't be needed
      for index in 0 1 2 3 4 5 6
      do
        if (( ( $isoval >= ${isolevel[$index]} ) && ( $isoval < ${isolevel[$index + 1]} ) ))
        then
          interval=$(( ${isolevel[$index + 1]} - ${isolevel[$index]} ))
          denoise=$(echo "scale=2; ${nrlevel[$index]} + ( ( ${nrlevel[$index + 1]} - ${nrlevel[$index]} ) * ( ( $isoval - ${isolevel[$index]} ) / $interval ) )" | bc | cut -d. -f1)
          unsharp=$(echo "scale=4; ${sharplevel[$index]} + ( ( ${sharplevel[$index + 1]} - ${sharplevel[$index]} ) * ( ( $isoval - ${isolevel[$index]} ) / $interval ) )" | bc)
        fi
      done
    fi

    echo
    echo "Converting $rawname from PEF to JPG (ISO "$isoval": NR "$denoise" sharpness "$unsharp")..."
    dcraw -w -q 3 -n $denoise -4 -T -c -t 0 -v -H 0 -S 4095 "$rawname" > "$tifname"

    echo "Processing..."
    convert "$tifname" -verbose -depth 16 -gamma $gamma -modulate 100,"$saturation",100 -sigmoidal-contrast $contrast -unsharp $lc -unsharp 0x1.2x"$unsharp"x0.03 -depth 8 -strip -quality $jpgqual "$jpegname"

    echo "Transferring EXIF and cleaning up..."
    exiv2 extract -f "$rawname"
    mv "$pefexif" "$jpgexif"
    exiv2 insert -f -M"set Exif.Photo.UserComment charset=Ascii $comment (NR=$denoise gamma=$gamma sat=$saturation contrast=$contrast lc=$lc unsharp=$unsharp qual=$jpgqual)" "$jpegname"
    rm "$jpgexif"
    rm "$tifname"

    echo "Done."
  fi
done
