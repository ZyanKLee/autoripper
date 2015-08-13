#!/bin/bash +x

. autoripper.conf # get config

if [ -f autoripper.conf.local ]
then
	. autoripper.conf.local
fi


$MYDIR/xbmc-notify.py "Started ripping $7" # xbmc notification of rip start

OUTPUTDIR=$1 WAVOUTPUTDIR=${1}/tmp/ OUTPUTTYPE=$2 $3 -c $4/abcde.conf ${8} # do the actual ripping

chown -R ${5}: "${6}/${7}" # change the owner to the recipient

lockfile-remove --lock-name $LOCKFILE # remove the lockfile

$MYDIR/updatexbmc.py # update the audio library in xbmc

$MYDIR/xbmc-notify.py "Finished ripping $7" # xbmc notification of rip end
