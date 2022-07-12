#! /bin/bash
CLEARDATE=$(date "+%d%m%y_%Hh%M")
TMPDIR="/tmp/glstyle/"

LOGDIR="/var/data/logs/"
LOGFILE="update_glstyle.log"

GLSTYLENAME="utagawavtt"
GLSTYLEDIR="/var/data/styles/"

CTNAME="tileserver-gl"

ctReload() {
	docker exec ${1} bash -c 'kill -HUP $(ls -l /proc/*/exe | sed -n "/\/node$/s/.*proc\/\([0-9]\+\)\/exe .*/\1/p")'
}

ctStart() {
	docker run --name ${1} -d --rm -it -v /var/data:/data -p 8080:80 maptiler/tileserver-gl
}

ctStatus() {
	docker ps -f NAME=${1} -f STATUS=running -q
}

writeToLog() {
	local LOGTIME=$(date "+%d-%m-%y %H:%M:%S")
	echo ${LOGTIME} ${1} >> ${LOGDIR}${LOGFILE}
}

mkdir -p ${TMPDIR} ${LOGDIR}
cd ${TMPDIR}

# Downloading style file on the repository
writeToLog "Downloading style file"
wget -q https://raw.githubusercontent.com/utagawal/MTBmaptiles/main/utagawavtt.json

if [ $? -eq 0 ]; then
	writeToLog "Style file downloaded"
	# Comparing repository's style file and local style file
	cmp -s ${GLSTYLEDIR}${GLSTYLENAME}/style.json ${TMPDIR}/utagawavtt.json

	if [ $? -eq 0 ]; then
		writeToLog "Style has not been updated"
		rm ${TMPDIR}/utagawavtt.json
	else
	# If files are differents..
		writeToLog "New style been processing.."
		# we save the local file..
		writeToLog "Saving old style to ${GLSTYLEDIR}${GLSTYLENAME}/style.json_${CLEARDATE}"
		cp ${GLSTYLEDIR}${GLSTYLENAME}/style.json ${GLSTYLEDIR}${GLSTYLENAME}/style.json_${CLEARDATE}
		# and replace it with the distant file..
		writeToLog "Applying new style"
		cp ${TMPDIR}/utagawavtt.json ${GLSTYLEDIR}${GLSTYLENAME}/style.json
		rm ${TMPDIR}/utagawavtt.json

		if [ -z $(ctStatus $CTNAME) ]; then
			# Container not running, so we start it
			writeToLog "Starting tileserver-gl"
			ctStart $CTNAME

			sleep 10

			if [ -z $(ctStatus $CTNAME) ]; then
				writeToLog "There is a problem while launching tileserver-gl container"
				echo "There is a problem while launching tileserver-gl container" | mail -s "tilserver-gl problem" ${ADMINEMAIL}
				exit
			else
				writeToLog "tileserver-gl started successfully"
			fi
		else
			# Container is running, we ask it to reload tileserver-gl config file
			writeToLog "Reloading tileserver-gl"
			ctReload $CTNAME

			if [ -z $(ctStatus $CTNAME) ]; then
				writeToLog "There is a problem while reloading tileserver-gl config"
				echo "There is a problem while reloading tileserver-gl config" | mail -s "tilserver-gl problem" ${ADMINEMAIL}
				exit
			else
				writeToLog "tileserver-gl reloaded successfully"
			fi
		fi
	fi
else
	writeToLog "Problem while downloading style from the repository : ${?}"
fi
