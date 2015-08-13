#!/bin/bash +x


# autoripper wrapper script to check if audio cd is new (as in: yet unripped)
# and run abcde accordingly

# CONFIG is in autoripper.conf

SELF=$0
DIRNAME=$(dirname $SELF)

. $DIRNAME/autoripper.conf

if [ -f $DIRNAME/autoripper.conf.local ]
then
	. $DIRNAME/autoripper.conf.local
fi

# this is serious stuff - avoid touching it unless you know what you are doing

# debug
#env | tee /var/log/autoripper-env.log

# debug end


# global variables

	PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:${MYDIR}

	# "selected" array of cherrypicked tracks
	declare -a selected

# stop global variables



# is cddb info valid and has cd info
#function check_cddb_info {
#	cddbinfocheck=0
#}


# eject cd
function do_eject {
	eject $CDROM
	lockfile-remove --lock-name $LOCKFILE
}


# check which audio cd this is and how many tracks it has
function get_cddb_info {

	DISCID="$( ${DISCIDTOOL} $CDROM )"
	ERR=$?

	if [ $ERR -ne 0 ]
	then
		echo "ERR: ${DISCIDTOOL} exits with error $ERR"
		exit $ERR
	fi

	CDDBTEMP=$(mktemp --tmpdir=/tmp/ CDDBTEMP.XXXX)
 	ERR=$( ${CDDBTOOL} query ${CDDBURL} ${CDDBPROTO} ${RECIPIENT} ${HOSTNAME} ${DISCID} > $CDDBTEMP 2>&1 ; echo $? )

	if [ $ERR -eq 0 ]
	then
		RETCODE=$( head -n1 $CDDBTEMP | cut -d ' '  -f 1 )

		TRACKS="$( echo $DISCID | cut -d ' ' -f 2 )"

		case $RETCODE in
			200) # one entry
				ARTISTALBUM=$( cat $CDDBTEMP | cut -d ' ' -f 4- | sed 's/\//-/g')
				;;
			210) # multiple entries
				ARTISTALBUM=$( cat $CDDBTEMP | head -n+2 | tail -n 1 | cut -d ' ' -f 3- | sed 's/\//-/g')
				;;
			202) # no entry
				do_eject
				echo "No CDDB entry for this disc"
				rm $CDDBTEMP
				exit 0
				;;
			*) # all other stuff
				do_eject
				echo "ERR: ${CDDBTOOL} exits with code $RETCODE"
				cat $CDDBTEMP
				rm $CDDBTEMP
				exit 0
				;;
		esac
	else
		do_eject
		echo "ERR: ${CDDBTOOL} exits with error $ERR"
	fi

	rm $CDDBTEMP

}

# compare local files and cddb info
function check_local {
	# is there a directory for this artist/album combination?
	echo "${DESTINATION}/${ARTISTALBUM}"

	if [ -d "${DESTINATION}/${ARTISTALBUM}" ] # album directory exists
	then
		# get number of audio-files in this dir
		CNT=$(find "${DESTINATION}/${ARTISTALBUM}" -type f -name '*.flac' | wc -l)

		if [ $CNT -lt $TRACKS ] # files in dir is lower than tracks on disc
		then
			# => return incomplete
			LOCALCHECK="incomplete"
		else
			# => return complete
			LOCALCHECK="complete"
		fi
	else # new album
		# => return newalbum
		LOCALCHECK="newalbum"
	fi
}


# select tracks according to check_local()
function select_tracks {
	for i in `seq -w 1 $TRACKS` # check if each number ...
	do
		if [ $(find "${DESTINATION}/${ARTISTALBUM}/" -type f -name "${i}*.flac" | wc -l) -eq 0 ] # ... is not there and if so ...
		then
			selected+=( "${i}" ) # ... add to list of selected tracks
		fi
	done
}


# do the actual ripping
function do_ripping {
	${MYDIR}/abcde.sh "${DESTINATION}" "${AUDIOFORMAT}" "${ABCDE}" "${MYDIR}" "${RECIPIENT}" "${DESTINATION}" "${ARTISTALBUM}" "${selected[*]}" &
}





# MAIN

function main {

	MULTIPLIER=1 # generates from 0 - 9.99999
	SLEEP=$( echo "scale=1; $RANDOM*$MULTIPLIER/32767" | bc )

	sleep $SLEEP

	if [ -f $LOCKFILE ]
	then
		lockfile-check --use-pid --lock-name $LOCKFILE
		LOCKCHECK=$?

		LOCKPID=$(cat $LOCKFILE)

		# if cat $LOCKFILE still running?
		if ( [ $( ps -p $LOCKPID -o pid,comm --no-heading | grep -q 'autoripper' ; echo $? ) -eq 0 ] || [ $( ps auxwww | grep -v grep | grep -q 'abcde' ; echo $? ) -eq 0 ] )
		then
			exit 0 # not running twice, die!
		fi

		# anything from here should only happen if autoripper or abcde are not running atm

		lockfile-remove --lock-name $LOCKFILE # removing stale lockfile
	fi

	lockfile-create --use-pid --lock-name $LOCKFILE # creating lockfile

	get_cddb_info

	check_local

	case ${LOCALCHECK} in
		"incomplete")
			select_tracks
			do_ripping
			;;
		"complete")
			do_eject
			;;
		"newalbum")
			do_ripping
			;;
		*)
			do_eject
			;;
	esac

#lockfile-remove --lock-name $LOCKFILE # removing lockfile after ripping ends in abcde.sh
}



if [ -z $TERM ]
then
	# if not run via terminal, log everything into a log file
	main 2>&1 >> $LOGFILE
else
	# run via terminal, only output to screen
	main
fi
