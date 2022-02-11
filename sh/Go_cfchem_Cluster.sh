#!/bin/bash
###
# Cluster all compounds in mols table.
###
#
T0=$(date +%s)
#
DBNAME="cfchemdb"
DBSCHEMA="public"
DBHOST="localhost"
#
TMPDIR="$(cd $HOME/../data/CFDE/data/; pwd)/tmp/"
printf "TMPDIR: ${TMPDIR}\n"
if [ ! -e $TMPDIR ]; then
	mkdir -p $TMPDIR
fi
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
#####################################################################
# 
#
#
source $(dirname $CONDA_EXE)/../bin/activate rdktools
#
###
# With 331927 compounds, the error is
# numpy.core._exceptions.MemoryError: Unable to allocate 410. GiB for an array
#ofile=${TMPDIR}/${DBNAME}_mols_clusters.pkl
#python3 -m rdktools.fp.App ClusterMols \
#	--i ${TMPDIR}/${DBNAME}_mols.smi \
#	--smilesColumn "cansmi" --idColumn "id" \
#	--o ${ofile}
###
# --output_as_tsv: Output FPs as TSV with id and feature names as columns.
# This file for input to Scikit-learn agglomerative (Ward) hierarchical
# clustering.
ofile=${TMPDIR}/${DBNAME}_mols_fp.pkl
python3 -m rdktools.fp.App FingerprintMols \
	--i ${TMPDIR}/${DBNAME}_mols.smi \
	--smilesColumn "cansmi" --idColumn "id" \
	--output_as_tsv \
	--o ${ofile}
conda deactivate
#
#
#####################################################################
#
###
#rm -rf $TMPDIR
#
printf "Elapsed time: %ds\n" "$[$(date +%s) - ${T0}]"
#
