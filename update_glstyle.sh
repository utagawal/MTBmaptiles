#! /bin/bash
CLEARDATE=$(date "+%d%m%y_%Hh%M")
TMPDIR="/tmp/glstyle/"

GLSTYLENAME="utagawavtt"
GLSTYLEDIR="/var/data/style/"

DOCKERRELOADCMD=$(docker exec tileserver-gl bash -c 'kill -HUP $(ls -l /proc/*/exe | sed -n "/\/node$/s/.*proc\/\([0-9]\+\)\/exe .*/\1/p")')

mkdir -p ${TMPDIR}
cd ${TMPDIR}

# Downloading style file on the repository
wget -q https://github.com/utagawal/MTBmaptiles/blob/main/utagawavtt.json

if [ $? -eq 0 ]; then
	# Comparing repository's style file and local style file
	# If files are differents..
	if cmp -s ${GLSTYLEDIR}${GLSTYLENAME}/style.json ${TMPDIR}/utagawavtt.json; then
		# we save the local file..
		cp ${GLSTYLEDIR}${GLSTYLENAME}/style.json ${GLSTYLEDIR}${GLSTYLENAME}/style.json_${CLEARDATE}
		# and replace it with the distant file..
		mv ${TMPDIR}/utagawavtt.json ${GLSTYLEDIR}${GLSTYLENAME}/style.json
		# then we reload tileserver-gl
		$DOCKERRELOADCMD
	fi
fi
