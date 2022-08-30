#!/bin/bash
###
#
DBNAME="cfchemdb"
DBSCHEMA="public"
DBHOST="unmtid-dbs.net"
DBPORT="5442"
DBUSR="commoner"
#
T0=$(date +%s)
#
# Password from ~/.pgpass, or add -W for prompt.
###
psql -qAF '\t' -h $DBHOST -d $DBNAME -p $DBPORT -U $DBUSR -f sql/sim_matrix_lincs.sql \
	|sed '$d' \
	>sim_matrix_lincs.tsv
#
printf "Elapsed time: %ds\n" "$[$(date +%s) - ${T0}]"
#
