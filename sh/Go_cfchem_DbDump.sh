#!/bin/bash
###
# 
set -e
#
T0=$(date +%s)
#
DBNAME="cfchemdb"
DBDIR="/home/data/CFDE/CFChemDb"
if [ ! -e "$DBDIR" ]; then
	mkdir -p $DBDIR
fi
#
tnames="$(echo '\d' |sudo -u postgres psql -At -d $DBNAME |grep table |awk -F '|' '{print $2}')"
for tname in $tnames ; do
	sudo -u postgres psql -e -d ${DBNAME} -c "ALTER TABLE $tname OWNER TO postgres"
done
#
dumpfile="$DBDIR/${DBNAME}.pgdump"
sudo -u postgres pg_dump --no-owner --no-privileges --format=custom -v -d ${DBNAME} >${dumpfile}
#
printf "Elapsed time: %ds\n" "$[$(date +%s) - ${T0}]"
#
