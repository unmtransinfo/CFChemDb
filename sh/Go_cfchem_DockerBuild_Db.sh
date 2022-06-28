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
T0=$(date +%s)
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
DBDIR="/home/data/CFDE/CFChemDb/"
dumpfile="$DBDIR/${DBNAME}.pgdump"
#
if [ ! -e "${dumpfile}" ]; then
	printf "Dump file not found: %s\n" "${dumpfile}"
	exit 1
fi
#
#Subdir needed for Docker.
if [ ! -e "${cwd}/data" ]; then
	mkdir ${cwd}/data/
fi
#
cp ${dumpfile} ${cwd}/data/
#
###
# Build image from Dockerfile.
dockerfile="${cwd}/Dockerfile_Db"
docker build -f ${dockerfile} -t ${INAME}:${TAG} .
#
printf "Elapsed time: %ds\n" "$[$(date +%s) - ${T0}]"
#
rm -f ${cwd}/data/${DBNAME}.pgdump
#
docker images
#
