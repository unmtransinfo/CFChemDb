SELECT
	mols.id,
	mols.name,
	drugcentral.id AS dc_id,
	drugcentral.name AS drugname,
	lincs.pert_name AS lincs_name,
	lincs.sig_count,
	refmet.pubchem_cid,
	refmet.refmet_name,
	ROUND(tanimoto_sml(rdkit_fp(mol_from_smiles('NCCc1ccc(O)c(O)c1'::cstring)), mols.fp)::NUMERIC, 2) similarity
FROM
	mols
JOIN
        drugcentral ON (drugcentral.mol_id = mols.id)
JOIN
	lincs ON (lincs.mol_id = mols.id)
JOIN
	refmet ON (refmet.mol_id = mols.id)
WHERE
	rdkit_fp(mol_from_smiles('NCCc1ccc(O)c(O)c1'::cstring))%mols.fp
ORDER BY
	similarity DESC
	;
