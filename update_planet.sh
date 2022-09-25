#! /bin/bash
ADMINEMAIL="olivier@omrs.fr"

CLEARDATE=$(date "+%d%m%y_%Hh%M")
CTNAME="tileserver-gl"

LOGDIR="/var/data/logs/"
LOGFILE="update_planet.log"

LOCKFILE="update_planet.lock"

MBTILESNAME="planet.mbtiles"
MBTILESDIR="/var/data/mbtiles/"

TMPDIR="/tmp/mbtiles/"

# Send a signal to tileserver-gl container, to reload it
ctReload() {
	docker kill -s HUP ${1} >/dev/null 2>&1
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
cd ${TMPDIR}

# Downloading planet.mbtiles.lz4
writeToLog "Downloading ${MBTILESNAME}"
wget -q -nd -np -r --timestamping --accept-regex='.*-planet\.mbtiles\.lz4$' -e robots=off https://osm.dbtc.link/mbtiles/

if [ $? -eq 0 ]; then
	writeToLog "${MBTILESNAME} downloaded."

	# Extracting planet.mbtiles.lz4 to planet.mbtiles
	writeToLog "extracting ${MBTILESNAME} ..."
	lz4 -d -f -q --rm *-planet.mbtiles.lz4

	if [ $? -eq 0 ]; then
		writeToLog "${MBTILESNAME} successfully extracted."

		# Dowloading its checksum
		wget -q -nd -np -r --accept-regex='.*-planet\.mbtiles\.sha256$' -e robots=off https://osm.dbtc.link/mbtiles/

		if [ $? -eq 0 ]; then
			# Verifying the checksum
			writeToLog "verifying ${MBTILESNAME} checksum ..."
			sha256sum --status -c *-planet.mbtiles.sha256

			if [ $? -eq 0 ]; then
				writeToLog "${MBTILESNAME} checksum OK."
				rm *-planet.mbtiles.sha256

				# Saving the current mbtiles
				writeToLog "Saving old planet.mbtiles to ${MBTILESNAME}.${CLEARDATE} ..."
				mv ${MBTILESDIR}${MBTILESNAME} ${MBTILESDIR}${MBTILESNAME}.${CLEARDATE}

				if [ $? -eq 0 ]; then
					# Deploying the new mbtiles
					writeToLog "Deploying new ${MBTILESNAME}."
					mv ${TMPDIR}/*-planet.mbtiles ${MBTILESDIR}${MBTILESNAME}

					if [ $? -eq 0 ]; then
						if [ -z $(ctStatus $CTNAME) ]; then
							# Container is not running, so we start it
							writeToLog "Starting tileserver-gl"
							ctStart $CTNAME
							if [ $? -eq 0 ]; then
								writeToLog "Started tileserver-gl successfully"
							else
								writeToLog "An error occur while starting tileserver-gl"
							fi
						else
							# Container is running, we ask it to reload tileserver-gl config file
							writeToLog "Reloading tileserver-gl"
							ctReload $CTNAME
							if [ $? -eq 0 ]; then
								writeToLog "Reloaded tileserver-gl successfully"
							else
								writeToLog "An error occur while reloading tileserver-gl"
							fi
						fi

						sleep 15

						if [ -z $(ctStatus $CTNAME) ]; then
							writeToLog "Unable to launch tileserver-gl with the new mbtiles file."
							echo "Unable to launch tileserver-gl with the new mbtiles file" | mail -s "tilserver-gl problem" ${ADMINEMAIL}
						else
							writeToLog "tileserver-gl started successfully with the new mbtiles file."
							echo "The new ${MBTILESNAME} hs been applied successfully" | mail -s "The new ${MBTILESNAME} hs been applied successfully" ${ADMINEMAIL}
						fi
					else
						writeToLog "A problem occured while moving ${MBTILESNAME} to ${MBTILESDIR}."
						writeToLog "Restoring the old ${MBTILESNAME} ..."
						mv ${MBTILESDIR}${MBTILESNAME}.${CLEARDATE} ${MBTILESDIR}${MBTILESNAME}
					fi
				else
					writeToLog "Unable to backup the current mbtiles file."
				fi
			else
				writeToLog "The checksum of ${MBTILESNAME} is incorrect."
			fi
		else
			writeToLog "A problem occured while downloading the checksum file."
		fi
	else
		writeToLog "A problem occured while uncompressing ${MBTILESNAME}.lz4."
	fi
else
	writeToLog "A problem occured while downloading ${MBTILESNAME}.lz4."
fi
lockRemove
