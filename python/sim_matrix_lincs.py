#!/usr/bin/env python3
"""
Computes a similarity matrix for a given table in CFChemDb. 
Computed in chunks, to avoid burdensome atomic SQL.
"""
###
import sys,os,logging,tqdm,math,argparse
import pandas as pd

from sqlalchemy import create_engine

NCHUNK = 100

def SimSQL(mol_idsA, mol_idsB, fptype):
  mol_idsA_str = (','.join([f"{mol_id}" for mol_id in mol_idsA]))
  mol_idsB_str = (','.join([f"{mol_id}" for mol_id in mol_idsB]))
  return f"""\
SELECT DISTINCT
	mols_a.id mol_id_a,
	mols_b.id mol_id_b,
	tanimoto_sml(mols_a.{fptype}, mols_b.{fptype}) tanimoto_similarity
FROM
	(SELECT id,{fptype} FROM mols WHERE id IN ({mol_idsA_str})) mols_a,
	(SELECT id,{fptype} FROM mols WHERE id IN ({mol_idsB_str})) mols_b
WHERE
        mols_a.id <= mols_b.id
ORDER BY
        mols_a.id, mols_b.id
"""

###
if __name__=="__main__":
  fptypes = ["ecfp", "fp"]
  tables = ["idg", "lincs", "reprotox", "refmet", "glygen", "drugcentral"]
  parser = argparse.ArgumentParser(description="CFChemDb Similarity Matrix generator")
  parser.add_argument("--o", dest="ofile", help="output (TSV)")
  parser.add_argument("--table", choices=tables, default="lincs", help="db table with mol_id column")
  parser.add_argument("--fptype", choices=fptypes, default="fp", help="Fingerprint type (column in mols table)")
  parser.add_argument("-v", "--verbose", default=0, action="count")
  args = parser.parse_args()

  logging.basicConfig(format='%(levelname)s:%(message)s', level=(logging.DEBUG if args.verbose>0 else logging.INFO))

  fout = open(args.ofile, "w") if args.ofile else sys.stdout

  engine = create_engine(f"postgresql://commoner:easement@unmtid-dbs.net:5442/cfchemdb")
  with engine.connect() as dbcon:
    df = pd.read_sql(f"SELECT DISTINCT mol_id FROM {args.table} WHERE mol_id IS NOT NULL", dbcon, coerce_float=False)
    N = df.shape[0]
    logging.info(f"Table: {args.table}; N_distinct_mols: {N}; comparisons: (N+1)*N/2 = {int((N+1)*N/2)}")
    tq = tqdm.tqdm(total=int((N+1)*N/2))
    mol_ids = df.iloc[:,0].sort_values(ascending=True).to_list()
    n_out=0; iA_chunk=0;
    N_chunk = math.ceil(N/NCHUNK)
    while True:
      mol_idsA_this = mol_ids[iA_chunk*NCHUNK:(iA_chunk+1)*NCHUNK]
      iB_chunk=iA_chunk
      while True:
        mol_idsB_this = mol_ids[iB_chunk*NCHUNK:(iB_chunk+1)*NCHUNK]
        logging.debug(f"iA_chunk: {iA_chunk+1}/{N_chunk}; jB_chunk: {iB_chunk+1}/{N_chunk}; nA: {len(mol_idsA_this)}; nB: {len(mol_idsB_this)}")
        sql_this = SimSQL(mol_idsA_this, mol_idsB_this, args.fptype)
        df_this = pd.read_sql(sql_this, dbcon)
        df_this.round(3).to_csv(fout, "\t", index=False, header=bool(n_out==0))
        logging.debug(f"nComparisonsThis: {df_this.shape[0]} (Should normally be {int((NCHUNK+1)*NCHUNK/2)})")
        n_out+=df_this.shape[0]
        tq.update(df_this.shape[0])
        iB_chunk+=1
        if iB_chunk*NCHUNK>=N: break
      iA_chunk+=1
      if iA_chunk*NCHUNK>=N: break
  tq.close()
  logging.info(f"Output similarity comparisons: {n_out}")
