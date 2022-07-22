SELECT DISTINCT
	xrefs.xref_value pubchem_cid,
	'https://pubchem.ncbi.nlm.nih.gov/compound/'||xrefs.xref_value pubchem_url,
	dc.id drugcentral_id,
	'https://drugcentral.org/drugcard/'||dc.id drugcentral_url 
FROM
	xrefs
	JOIN mols ON mols.id = xrefs.mol_id
	JOIN drugcentral dc ON dc.mol_id = mols.id
WHERE 
	xrefs.xref_type = 'pubchem_cid'
	AND xrefs.xref_value IS NOT NULL
	AND dc.id IS NOT NULL
ORDER BY
        xrefs.xref_value
	;

