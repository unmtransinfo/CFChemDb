SELECT DISTINCT
	a.xref_value pubchem_cid,
	'https://pubchem.ncbi.nlm.nih.gov/compound/'||a.xref_value pubchem_url,
	b.xref_value chebi_id,
	'https://www.ebi.ac.uk/chebi/searchId.do?chebiId=CHEBI:'||b.xref_value chebi_url
FROM
	xrefs a,
	xrefs b
WHERE 
	a.mol_id = b.mol_id
	AND a.xref_type = 'pubchem_cid'
	AND b.xref_type = 'chebi_id'
ORDER BY
        a.xref_value
	;

