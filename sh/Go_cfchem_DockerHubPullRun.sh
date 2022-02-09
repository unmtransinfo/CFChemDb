#!/bin/bash
###
# Instantiate and run containers.
# -dit = --detached --interactive --tty
###
set -e
#
if [ $(whoami) != "root" ]; then
	echo "${0} should be run as root or via sudo."
	exit
fi
#
ORG="unmtransinfo"
INAME_DB="cfchemdb_db"
TAG="latest"
#
docker pull $ORG/${INAME_DB}:${TAG}
#
APPPORT_DB=5432
DOCKERPORT_DB=5442
#
###
# May need to stop and remove current container first:
if [ "$(docker container ls -a |grep ${INAME_DB}_container)" ]; then
	docker container stop ${INAME_DB}_container
	docker container rm ${INAME_DB}_container
fi
#
# Note that "run" is equivalent to "create" + "start".
docker run -dit --restart always --name "${INAME_DB}_container" \
	-p ${DOCKERPORT_DB}:${APPPORT_DB} ${ORG}/${INAME_DB}:${TAG}
#
docker container ls -a
#
docker container logs "${INAME_DB}_container"
#
###
echo "Sleep while db server starting up..."
sleep 10
###
# Test db.
docker exec "${INAME_DB}_container" sudo -u postgres psql -l
#
# Pw "easement"
psql -h localhost -p 5442 -d cfchemdb -U commoner -c "SELECT * FROM meta"
psql -h localhost -p 5442 -d cfchemdb -U commoner -c "SELECT COUNT(*) FROM mols"
#
###
# Copy this file to cloud server thus:
# scp sh/Go_DockerHubPullRun.sh unmtid-dbs.net:~/bin/
#
