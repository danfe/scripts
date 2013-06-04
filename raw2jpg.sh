#!/bin/sh
#
# Zeus V Panchenko
# mailt0: zeus at camb d0t us
# ICQ: 198888060
#

#
## netpbm stuff
#
PNMGAMMA=${PNMGAMMA=/usr/local/bin/pnmgamma}
pnmgammaopt=" -cieramp 1.95 " # another good numbers are: 1.985, 1.87, 3.5, 0.87

PNMNORM=${PNMNORM=/usr/local/bin/pnmnorm}
pnmnormopt=" -bpercent 0.000005 -wpercent 0.9999999 "

PAMGAUSS=${PAMGAUSS=/usr/local/bin/pamgauss}
# pamgaussopt=" 9 11 -sigma=8 -tupletype=GRAYSCALE " # this increases processing time up to 150 s/shot :(
pamgaussopt=" 7 9 -sigma=8 -tupletype=GRAYSCALE "

PAMTOPNM=${PAMTOPNM=/usr/local/bin/pamtopnm}

`$PAMGAUSS $pamgaussopt | $PAMTOPNM > .BLUR.PGM`

PNMCONVOL=${PNMCONVOL=/usr/local/bin/pnmconvol}
pnmconvolopt=" .BLUR.PGM -nooffset "

PAMMASKSHARPEN=${PAMMASKSHARPEN=/usr/local/bin/pammasksharpen}
pammasksharpenopt=" -sharpness=.317 "

PNMTOJPEG=${PNMTOJPEG=/usr/local/bin/pnmtojpeg}
pnmtojpegopt="-quality=87 -progressive -optimize "

EXIFTOOL=${EXIFTOOL=/usr/local/bin/exiftool}

DCRAW=${DCRAW=/usr/local/bin/dcraw}

esc=""
cyanf="${esc}[36m"
greenf="${esc}[32m"
purplef="${esc}[35m"
redf="${esc}[31m"
yellowf="${esc}[33m"
reset="${esc}[0m"

cmsg ()
{
    COLOR=$1
    MSG="$2"
    echo -n "$COLOR$MSG$reset"
}

# just the help
help ( )
{
echo "${redf}NAME${reset}
	raw2jpg -- is the shell wrapper for dcraw, net-pbm and ExifTool
	to extract data from RAW files and decoding them to JPEG format.

${redf}SYNOPSIS
	raw2jpg [-h]

DESCRIPTION${reset}
	In general this script does like this:

	dcraw -4 -f -w -v -c FILE.CRW | \\
	pnmgamma $pnmgammaopt | \\
	pnmnorm $pnmnormopt | > FILE.PPM
	pamgauss $pamgaussopt | pamtopnm > .BLUR.PGM
	pnmconvol $pnmconvolopt FILE.PPM > FILE.BLUR.PPM
	pammasksharpen $pammasksharpenopt FILE.BLUR.PPM FILE.PPM | \\
	pnmtojpeg $pnmtojpegopt > FILE.JPG
	rm .BLUR.PGM FILE.BLUR.PPM FILE.PPM
${redf}OPTIONS${reset}
	-h	this very help

${redf}SEE ALSO${reset}
	dcraw(1), pnmgamma, pnmtojpeg <http://netpbm.sourceforge.net>
	ExifTool <http://www.sno.phy.queensu.ca/~phil/exiftool/>"
return 0
}

if [ "$1" = "-h" -o "$1" = "--help" ];then
	help
	exit 1
fi

sound="/mnt/ad1s1e/STUFF/PROJECTS/raw2jpg/Motroskin-Hura.mp3"

# DIALOGUES are here
DIALOG=${DIALOG=/usr/bin/dialog}

#
## RAW file extention request dialog
#
$DIALOG --title "RAW EXTENTION" --clear \
	--hline "Press arrows, TAB or Enter" \
	--inputbox "Here is the extention for\n \
RAW files to be processed.\n" -1 -1 "crw" 2> /tmp/ext.tmp.$$

retval=$?

input=`cat /tmp/ext.tmp.$$`
rm -f /tmp/ext.tmp.$$

case $retval in
  0)
    ext=$input;;
  1)
    echo "Extention input refusal.";
    exit 1;;
  255)
    echo "ESC pressed in extention input section.";
    exit 1;;
esac

EXTENTION="."$ext

#
## THM file extention request dialog
#
$DIALOG --title "THM EXTENTION" --clear \
	--hline "Press arrows, TAB or Enter" \
	--inputbox "Here is the extention for\n \
THM files to be processed.\n" -1 -1 "thm" 2> /tmp/thm.ext.tmp.$$

retval=$?

input=`cat /tmp/thm.ext.tmp.$$`
rm -f /tmp/thm.ext.tmp.$$

case $retval in
  0)
    thmext=$input;;
  1)
    echo "Extention input refusal.";
    exit 1;;
  255)
    echo "ESC pressed in extention input section.";
    exit 1;;
esac

THMEXTENTION="."$thmext

#
## file/s choosing dialog
#
find -s ./ -depth 1 -name "*.$ext" > /tmp/ftreebox.tmp.$$

if [ ! -s /tmp/ftreebox.tmp.$$ ]; then
	echo ""
	echo "No $EXTENTION extention files found ..."
	exit 1
fi

$DIALOG --clear --title "FILE TREE" \
	--hline "Press arrows, TAB or Enter" \
	--ftree "/tmp/ftreebox.tmp.$$" "/" \
	"Choose file to process or cansel for all" \
	-1 -1 10 2>/tmp/ftree.tmp.$$

retval=$?

choice=`cat /tmp/ftree.tmp.$$`

case $retval in
  0)
  filetoprocess=$choice;;
  1)
  filetoprocess=1;;
  255)
    [ -z "$choice" ] || echo $choice ;
    echo "ESC pressed.";;
esac

rm -f /tmp/ftreebox.tmp.$$ /tmp/ftree.tmp.$$

if [ "$filetoprocess" -eq 1 ]; then
	DIR="*"$EXTENTION
else
	DIR=$filetoprocess
fi

#
## dcraw options request dialog
#
if [ -s .raw2jpg.log ]
then
	dcrawopt=`cat .raw2jpg.log`
else
	dcrawopt="-4 -w -f"
fi

$DIALOG --title "DCRAW options" --clear \
--hline "Press arrows, TAB or Enter" \
--inputbox "-v -c are preset\n\
for noisy images -B 1 2 is rather good\n\
example:\n\n\
-t 0 -a -B 1 2\n" -1 -1 "$dcrawopt" 2> /tmp/dcrawopt.tmp.$$

retval=$?

input=`cat /tmp/dcrawopt.tmp.$$`
rm -f /tmp/dcrawopt.tmp.$$

case $retval in
  0)
    dcrawopt=" -v -c "$input;
    echo $input > .raw2jpg.log;;
  1)
    echo "DCRAW options input refusal.";
    exit 1;;
  255)
    echo "ESC pressed in DCRAW options input section.";
    exit 1;;
esac

#
## Whether to extract JpegFromRaw data or not
#
$DIALOG --title "JpegFromRaw" --clear \
	--hline "Press arrows, TAB or Enter" \
        --yesno "NOT extract JpegFromRaw data or not" 10 30

case $? in
  0)
    jpegfromraw=0;;
  1)
    jpegfromraw=1;;
  255)
    echo "ESC pressed.";
    exit 1;;
esac

if [ ! -d "JpgFromRaw" -a "$jpegfromraw" -eq 1 ];then
	mkdir JpgFromRaw
fi

#
## whether to bell
#
$DIALOG --title "BELL" --clear \
	--hline "Press arrows, TAB or Enter" \
	--yesno "NOT to play sound to notify the finish of processing" 10 30

case $? in
  0)
    bell=0;;
  1)
    bell=1;;
  255)
    echo "ESC pressed in bell input section.";
    exit 1;;
esac

filesnumber=`ls -al $DIR | wc -l | tr -d ' '`
filecounter=1
start=`date +%H:%M:%S`
starts=`date +%s`

echo
cmsg ${cyanf} "Start of the "
cmsg ${purplef} $filesnumber
cmsg ${cyanf} " files processing: "
cmsg ${purplef} " $start"
echo
cmsg ${cyanf} "========================================================="
echo


for file in $DIR
do
    BASERAW=${file##*/}
    BASE=${BASERAW%$EXTENTION}
    startloop=`date +%H:%M:%S`
    startloops=`date +%s`

    echo "${purplef}$startloop${reset} ${cyanf}start processing file${reset} ${purplef}$filecounter${reset} ${cyanf}of${reset} ${purplef}$filesnumber${reset} ${cyanf}(${reset} ${purplef}$file${reset} ${cyanf})${reset}"

    echo
    CMD_STR="$DCRAW $dcrawopt $file |\\
$PNMGAMMA $pnmgammaopt | $PNMNORM $pnmnormopt > $BASE.PPM
$PAMGAUSS $pamgaussopt | pamtopnm > .BLUR.PGM
$PNMCONVOL $pnmconvolopt $BASE.PPM > $BASE.BLUR.PPM
$PAMMASKSHARPEN $pammasksharpenopt $BASE.BLUR.PPM $BASE.PPM |\\
$PNMTOJPEG $pnmtojpegopt > $BASE.JPG"
    cmsg ${greenf} "$CMD_STR"
    echo
    echo

    $DCRAW $dcrawopt $file | $PNMGAMMA $pnmgammaopt | $PNMNORM $pnmnormopt > $BASE.PPM
    $PNMCONVOL $pnmconvolopt $BASE.PPM > $BASE.BLUR.PPM
    $PAMMASKSHARPEN $pammasksharpenopt $BASE.BLUR.PPM $BASE.PPM | $PNMTOJPEG $pnmtojpegopt > $BASE.JPG
    rm $BASE.PPM $BASE.BLUR.PPM

    # whethter to extract jpegfromraw
    if [ "$jpegfromraw" -eq 1 ]; then
       	# whether JpgFromRaw file exists?
	if [ ! -e "JpgFromRaw/JpgFromRaw.$BASE.JPG" ]; then
	    $EXIFTOOL -b -JpgFromRaw $file > JpgFromRaw/JpgFromRaw.$BASE.JPG
	    echo "${greenf}JpgFromRaw/JpgFromRaw.$BASE.JPG not exists${reset}"
	    echo -n "${greenf}RAW EXIFs => JpgFromRaw JPG${reset}"
	    $EXIFTOOL -TagsFromFile $BASE$THMEXTENTION -TagsFromFile $BASE$EXTENTION JpgFromRaw/JpgFromRaw.$BASE.JPG
	    rm JpgFromRaw/*.JPG_original
	fi
    fi

    # copy EXIFs from THM and RAW to JPG
    echo -n "${greenf}THM + RAW EXIFs => JPG"
    $EXIFTOOL -TagsFromFile $BASE$THMEXTENTION -TagsFromFile $BASE$EXTENTION -UserComment="$CMD_STR" $BASE.JPG
    
    # thumbnail rotating if needed
    orientation=`$EXIFTOOL -t -n -S -orientation $BASE$THMEXTENTION`
    echo "Orientation: $orientation"
    case $orientation in
	6) angle=90;;
	3) angle=180;;
	8) angle=270;;
    esac

    if [ "$orientation" -gt 1 ]; then
	JPEGTRAN=${JPEGTRAN=/usr/local/bin/jpegtran}
	$EXIFTOOL -b -ThumbnailImage $BASE$EXTENTION > THUMB
	$JPEGTRAN -copy none -rotate $angle -outfile THUMB.ROT THUMB
	$EXIFTOOL '-ThumbnailImage<=THUMB.ROT' $BASE.JPG
	rm THUMB THUMB.ROT
	$EXIFTOOL -n -Orientation=1 $BASE.JPG	# since EXIFs are taken from CRW, and file was rotated by dcraw
	orientation=1
    fi

    rm *.JPG_original
    
    stoploop=`date +%H:%M:%S`
    stoploops=`date +%s`
    loopsec=`expr $stoploops - $startloops`
    echo "${reset}${purplef}$stoploop${reset} ${cyanf}stop processing${reset} ${purplef}$file${reset} ${cyanf}(${reset} ${purplef}$loopsec${reset} ${cyanf}seconds )${reset}"
    echo ""
    filecounter=`expr $filecounter + 1`
done

rm .BLUR.PGM

filecounter=`expr $filecounter - 1`
stop=`date +%H:%M:%S`
stops=`date +%s`
sec=`expr $stops - $starts`
average=`expr $sec / $filecounter`
echo "${cyanf}=========================================================${reset}"
echo "${cyanf}Start of the processing:${reset} ${purplef}$start${reset}"
echo "${cyanf}Stop  of the processing:${reset} ${purplef}$stop${reset}"
echo "${purplef}$filecounter${reset} ${cyanf}files processing was lasting${reset} ${purplef}$sec${reset} ${cyanf}seconds"
echo "average processing time for each file is${reset} ${purplef}$average${reset} ${cyanf}seconds${reset}"

# bell or not to bell
# really it's on your own how to do that
# perhapse you'd wanna output something to /dev/speaker instead
#
if [ "$bell" -eq 1 ]
then
    ISXMMS=`pgrep xmms`
    if [ $? ]
    then
	xmmsctrl pause
	mpg123 -q $sound $sound
	xmmsctrl pause
    else
	mpg123 -q $sound $sound
    fi
    echo
    echo
    echo "${yellowf}TADAAAAAAM!!!${reset}"
fi

exit 0
