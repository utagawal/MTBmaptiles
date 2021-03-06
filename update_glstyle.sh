#! /bin/bash
ADMINEMAIL="olivier@omrs.fr"

CLEARDATE=$(date "+%d%m%y_%Hh%M")
CTNAME="tileserver-gl"

LOGDIR="/var/data/logs/"
LOGFILE="update_glstyle.log"

LOCKFILE="update_glstyle.lock"

GLSTYLENAME="utagawavtt"
GLSTYLEDIR="/var/data/styles/"

TMPDIR="/tmp/glstyle/"

# Send a signal to tileserver-gl container, to reload it
ctReload() {
	docker exec ${1} bash -c 'kill -HUP $(ls -l /proc/*/exe | sed -n "/\/node$/s/.*proc\/\([0-9]\+\)\/exe .*/\1/p")'
}

# Start tileserver-gl container
ctStart() {
	docker run --name ${1} -d --rm -it -v /var/data:/data -p 8080:80 maptiler/tileserver-gl
}

# Check if tileserver-gl is running
ctStatus() {
	docker ps -f NAME=${1} -f STATUS=running -q
}

# Check the presence of a lock file and if it is obsolete
#
# If a lock file exists, but no process is running with the
# pid written inside, we erase it and return that the lock
# file does not exists.
lockCheck() {
	if [ -f ${TMPDIR}${LOCKFILE} ]; then
		if [ -z "$(ps --no-headers $(cat ${TMPDIR}${LOCKFILE}))" ]; then
			rm ${TMPDIR}${LOCKFILE}
			return 1
		fi
		return 0
	else
		return 1
	fi
}

# Remove the lock file
lockRemove() {
	rm -f ${TMPDIR}${LOCKFILE}
}

# Write the lock file
lockWrite() {
	echo $$ > ${TMPDIR}${LOCKFILE}
}

writeToLog() {
	local LOGTIME=$(date "+%d-%m-%y %H:%M:%S")
	echo ${LOGTIME} ${1} >> ${LOGDIR}${LOGFILE}
}

if [ -z $(lockCheck) ]; then
	lockWrite
else
	writeToLog "The script is already running"
	exit
fi

mkdir -p ${TMPDIR} ${LOGDIR}

# Downloading style file on the repository
writeToLog "Downloading ${GLSTYLENAME}.json"
wget -q https://raw.githubusercontent.com/utagawal/MTBmaptiles/main/${GLSTYLENAME}.json -P ${TMPDIR}

if [ $? -eq 0 ]; then
	writeToLog "Style file downloaded"
	# Comparing repository's style file and local style file
	cmp -s ${GLSTYLEDIR}${GLSTYLENAME}.json ${TMPDIR}${GLSTYLENAME}.json

	if [ $? -eq 0 ]; then # Files are identicals
		writeToLog "Style has not been updated"
		rm ${TMPDIR}${GLSTYLENAME}.json

	else # Files are differents
		writeToLog "Saving old style to ${GLSTYLEDIR}${GLSTYLENAME}.json_${CLEARDATE}"
		cp ${GLSTYLEDIR}${GLSTYLENAME}.json ${GLSTYLEDIR}${GLSTYLENAME}.json_${CLEARDATE}

		writeToLog "Applying new style"
		cp ${TMPDIR}${GLSTYLENAME}.json ${GLSTYLEDIR}${GLSTYLENAME}.json
		rm ${TMPDIR}${GLSTYLENAME}.json

		if [ -z $(ctStatus $CTNAME) ]; then
			# Container is not running, so we start it
			writeToLog "Starting tileserver-gl"
			ctStart $CTNAME

		else
			# Container is running, we ask it to reload tileserver-gl config file
			writeToLog "Reloading tileserver-gl"
			ctReload $CTNAME
		fi

		sleep 30

		if [ -z $(ctStatus $CTNAME) ]; then
			writeToLog "The tileserver-gl container is down."
			writeToLog "Restoring the before last style file : ${GLSTYLENAME}.json_${CLEARDATE}"
			cp ${GLSTYLEDIR}${GLSTYLENAME}.json_${CLEARDATE} ${GLSTYLEDIR}${GLSTYLENAME}.json

			writeToLog "Trying to launch tilserver-gl, please wait."
			ctStart $CTNAME
			sleep 30

			if [ -z $(ctStatus $CTNAME) ]; then
				echo "Unable to launch tileserver-gl with the before last style file" | mail -s "tilserver-gl problem" ${ADMINEMAIL}
				exit
			else
				writeToLog "tileserver-gl started successfully with ${GLSTYLENAME}.json_${CLEARDATE}."
				echo "${GLSTYLENAME}.json_${CLEARDATE} applied successfully" | mail -s "New style can not be applied on tilserver-gl" ${ADMINEMAIL}
			fi
		else
			writeToLog "New style applied successfully."
			echo "New style applied successfully" | mail -s "A new style has been applied on tilserver-gl" ${ADMINEMAIL}
		fi
	fi
else
	writeToLog "Problem while downloading style from the repository : "${?}
	echo "Problem while downloading style from the repository." | mail -s "Unable to download the new style" ${ADMINEMAIL}
fi
lockRemove
