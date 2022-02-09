#!/bin/bash
###
# Takes ~5-20min, depending on server, mostly pg_restore.
###
#
set -e
set -x
#
if [ $(whoami) != "root" ]; then
	echo "${0} should be run as root or via sudo."
	exit
fi
#
cwd=$(pwd)
#
DBNAME="cfchemdb"
#
docker version
#
INAME="${DBNAME}_db"
TAG="latest"
#
#Subdir needed for Docker.
if [ ! -e "${cwd}/data" ]; then
	mkdir ${cwd}/data/
fi
#
tnames="$(echo '\d' |sudo -u postgres psql -At -d $DBNAME |grep table |awk -F '|' '{print $2}')"
for tname in $tnames ; do
	sudo -u postgres psql -e -d ${DBNAME} -c "ALTER TABLE $tname OWNER TO postgres"
done
#
TMPDIR="/tmp/CFChemDb"
if [ ! -e "$TMPDIR" ]; then
	mkdir -p $TMPDIR
fi
dumpfile="$TMPDIR/${DBNAME}.pgdump"
sudo -u postgres pg_dump --no-owner --no-privileges --format=custom -d ${DBNAME} >${dumpfile}
cp ${dumpfile} ${cwd}/data/
#
T0=$(date +%s)
#
###
# Build image from Dockerfile.
dockerfile="${cwd}/Dockerfile_Db"
docker build -f ${dockerfile} -t ${INAME}:${TAG} .
#
printf "Elapsed time: %ds\n" "$[$(date +%s) - ${T0}]"
#
rm -f ${cwd}/data/${DBNAME}.pgdump
rm -f ${dumpfile}
#
docker images
#
