SELECT
	mols_a.id mol_id_a,
	mols_a.lincs_id lincs_id_a,
	mols_b.id mol_id_b,
	mols_b.lincs_id lincs_id_b,
	ROUND(tanimoto_sml(mols_a.ecfp, mols_b.ecfp)::NUMERIC, 3) tanimoto_similarity
FROM
	(SELECT lincs.lcs_id lincs_id,lincs.mol_id,mols.id,mols.ecfp FROM lincs INNER JOIN mols ON lincs.mol_id = mols.id) mols_a,
	(SELECT lincs.lcs_id lincs_id,lincs.mol_id,mols.id,mols.ecfp FROM lincs INNER JOIN mols ON lincs.mol_id = mols.id) mols_b
WHERE
        mols_a.id <= mols_b.id
ORDER BY
        mols_a.id, mols_b.id
	;
