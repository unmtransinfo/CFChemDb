# CFChemDb Cheminformatics

Cheminformatics details of CFChemDb are described here.
The RDKit PostgreSql cartridge is employed to provide chemical intelligence via
the RDKit SQL API, and support chemical objects (e.g. molecules) as custom
classes. In addition, RDKit is used for ingestion workflows, to
harmonize chemical structures via molecular graph
standardization and canonicalization.

See [RDKit](https://www.rdkit.org/),
[RDKit Cartridge](https://www.rdkit.org/docs/Cartridge.html) and
[rdkit-tools](https://github.com/jeremyjyang/rdkit-tools)
for further details.

Each unique chemical compound in the database is represented by the shared
`mols` table, which contains the following columns:


| *column* | *datatype* | *source* | *description* |
|:---|:---|---|---|
|**id**|integer|serial, auto-incremented|CFChemDb unique molecule ID, primary key|
|**name**|VARCHAR(100)|PubChem, custom niceness heuristic|human-friendly name|
|**cansmi**|VARCHAR(2000)|function mol\_to\_smiles()|RDKit standardized, canonical, non-isomeric SMILES|
|**molecule**|MOL|function mol\_from\_smiles()|RDKit molecule object|
|**fp**|BFP|function rdkit\_fp()|RDKit binary fingerprint (path-based, Daylight-like, 1024 bits)|
|**ecfp**|BFP|function morganbv\_fp()|RDKit binary fingerprint (Morgan, radius=2, ECFP4-like, 512 bits)|

* Standardization of molecules is via module [rdktools.standard](https://github.com/jeremyjyang/rdkit-tools/blob/master/rdktools/standard/App.py)
* Niceness heuristic selection of human-friendly names via module [BioClients.pubchem](https://github.com/jeremyjyang/BioClients/blob/master/BioClients/pubchem/Client.py)
