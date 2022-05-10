#!/bin/bash
###
# Add XRefs for all compounds in mols table.
###
#
T0=$(date +%s)
#
DBNAME="cfchemdb"
DBSCHEMA="public"
DBHOST="localhost"
#
TNAME="xrefs"
#
TMPDIR="$(cd $HOME/../data/CFDE/data/; pwd)/tmp/$(date +'%Y-%m-%d')"
printf "TMPDIR: ${TMPDIR}\n"
if [ ! -e $TMPDIR ]; then
	mkdir -p $TMPDIR
fi
#
# Input TSV cols: SMILES, MOL_ID, XREF1[, XREF2, ...] (1+ xrefs)
function LoadXrefsFile {
  xreffile=$1
  dbname=$2
  tname=$3
  colnames=$(cat ${xreffile} |head -1 |sed 's/\([a-z]\)\([A-Z]\)/\1_\2/g'|tr '[:upper:]' '[:lower:]')
  printf "colnames: ${colnames}\n"
  xrefnames=$(echo $colnames |sed 's/smiles\s//' |sed 's/name\s//')
  n_xrefs=$(echo $xrefnames |wc -w)
  printf "xrefnames ($n_xrefs): ${xrefnames}\n"
  for xrefname in $xrefnames ; do
    psql -e -d $dbname -c "ALTER TABLE $tname ADD COLUMN $xrefname VARCHAR(32)"
  done
  #
  N=$[$(cat ${xreffile} |wc -l)-1]
  i=0
  while [ $i -lt $N ]; do
          i=$[$i + 1]
          line=$(cat ${xreffile} |sed '1d' |sed "${i}q;d")
          mol_id=$(echo "$line" |awk -F '\t' '{print $2}')
    vals=$(echo $line |awk '{$1=$2=""; print $0}')
    vals=$(echo $vals |sed "s/\s/', '/g" |sed "s/^\(.*\)$/'\1'/")
    printf "${i}/${N}. mol_id=${mol_id}; adding ${n_xrefs} xrefs: $(echo $xrefnames |
sed 's/\s/, /g')\n"
    psql -d $dbname -c "UPDATE $tname SET ($(echo $xrefnames |sed 's/\s/, /g')) = ROW(${vals}) WHERE mol_id = ${mol_id}"
  done
}
#
###
# SMILES,MOL_ID from mols table:
psql -d $DBNAME -c "COPY (SELECT cansmi, id FROM mols ORDER BY id) TO STDOUT WITH (FORMAT CSV,HEADER,DELIMITER E'\t')" \
	>${TMPDIR}/${DBNAME}_mols.smi
#
###
if [ ! "$CONDA_EXE" ]; then
	CONDA_EXE=$(which conda)
fi
if [ ! "$CONDA_EXE" -o ! -e "$CONDA_EXE" ]; then
	echo "ERROR: conda not found."
	exit
fi
#
###
psql -e -d $DBNAME -c "DROP TABLE IF EXISTS $TNAME"
psql -e -d $DBNAME -c "CREATE TABLE $TNAME (mol_id INTEGER, xref_type VARCHAR(32), xref_value VARCHAR(32))"
#
#####################################################################
# PubChem
# First copy existing PubChem CIDs (may be duplicates):
psql -e -d $DBNAME -c "INSERT INTO $TNAME (mol_id, xref_type, xref_value) SELECT mol_id, 'pubchem_cid', pubchem_cid FROM idg"
psql -e -d $DBNAME -c "INSERT INTO $TNAME (mol_id, xref_type, xref_value) SELECT mol_id, 'pubchem_cid', pubchem_cid FROM refmet"
psql -e -d $DBNAME -c "INSERT INTO $TNAME (mol_id, xref_type, xref_value) SELECT mol_id, 'pubchem_cid', pubchem_cid FROM glygen"
psql -e -d $DBNAME -c "INSERT INTO $TNAME (mol_id, xref_type, xref_value) SELECT mol_id, 'pubchem_cid', pubchem_cid FROM reprotox"
#
# Deduplicate and create index.
psql -e -d $DBNAME -c "ALTER TABLE $TNAME ADD COLUMN id SERIAL PRIMARY KEY"
psql -e -d $DBNAME -c "DELETE FROM $TNAME a USING $TNAME b WHERE a.id<b.id AND a.mol_id=b.mol_id AND a.xref_type=b.xref_type AND a.xref_value=b.xref_value"
psql -e -d $DBNAME -c "ALTER TABLE $TNAME DROP COLUMN id"
psql -e -d $DBNAME -c "CREATE INDEX mol_id_idx ON $TNAME (mol_id)"
#
# Export compounds still needing PubChem CIDs:
###
psql -e -d $DBNAME -c "ALTER TABLE mols ADD COLUMN has_cid BOOLEAN DEFAULT FALSE"
psql -e -d $DBNAME -c "UPDATE mols SET has_cid = TRUE FROM $TNAME WHERE mols.id=$TNAME.mol_id"
psql -e -d $DBNAME -c "SELECT has_cid,COUNT(id) FROM mols GROUP BY has_cid"
psql -d $DBNAME -c "COPY (SELECT cansmi,id FROM mols WHERE NOT has_cid) TO STDOUT WITH (FORMAT CSV,HEADER,DELIMITER E'\t')" \
	>${TMPDIR}/${DBNAME}_mols_needing-pubchem.smi
psql -e -d $DBNAME -c "ALTER TABLE mols DROP COLUMN has_cid"
#
xreffile=${TMPDIR}/${DBNAME}_mols_xrefs-pubchem.smi
python3 -m BioClients.pubchem.Client get_smi2cid \
	--i ${TMPDIR}/${DBNAME}_mols_needing-pubchem.smi \
	--o ${xreffile}
#
LoadXrefsFile $xreffile $DBNAME $TNAME
#
#####################################################################
# ChEBI
xreffile=${TMPDIR}/${DBNAME}_mols_xrefs-chebi.smi
if [ ! -e "$xreffile" ]; then

	printf "XRef file generated: ${xreffile}\n"
else
	printf "XRef file exists: ${xreffile}\n"
fi
#
LoadXrefsFile $xreffile $DBNAME $TNAME
###
#rm -rf $TMPDIR
#
printf "Elapsed time: %ds\n" "$[$(date +%s) - ${T0}]"
#
