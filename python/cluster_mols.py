#!/usr/bin/env python3
###
"""
Scikit-learn agglomerative clustering designed for molecular datasets
and chemical fingerprints.

https://scikit-learn.org/stable/modules/generated/sklearn.cluster.AgglomerativeClustering.html
https://scikit-learn.org/stable/auto_examples/cluster/plot_agglomerative_dendrogram.html
Hierarchical, agglomerative clustering using Scikit-learn.
"""
import sys,os,time,argparse,logging
import pandas as pd
import numpy as np
import matplotlib as mpl
from matplotlib import pyplot as plt
import scipy
from scipy.cluster.hierarchy import dendrogram

import sklearn
from sklearn.cluster import AgglomerativeClustering

#############################################################################
def plot_dendrogram(model, **kwargs):
    # Create linkage matrix and then plot the dendrogram
    # create the counts of samples under each node
    counts = np.zeros(model.children_.shape[0])
    n_samples = len(model.labels_)
    for i, merge in enumerate(model.children_):
        current_count = 0
        for child_idx in merge:
            if child_idx < n_samples:
                current_count += 1  # leaf node
            else:
                current_count += counts[child_idx - n_samples]
        counts[i] = current_count

    linkage_matrix = np.column_stack(
        [model.children_, model.distances_, counts]
    ).astype(float)

    # Plot the corresponding dendrogram
    dendrogram(linkage_matrix, **kwargs)

#############################################################################
def Demo():
  from sklearn.datasets import load_iris
  iris = load_iris()
  X = pd.DataFrame(iris.data, columns=iris.feature_names)
  logging.info(f"X: {X.shape[0]}x{X.shape[1]}")
  model = AgglomerativeClustering(
	linkage="ward", affinity="euclidean",
	compute_distances=True,
	distance_threshold=0, n_clusters=None) # distance_threshold=0 ensures full tree.
  model = model.fit(X)
  DescribeModel(model)
  plt.title("Hierarchical Clustering Dendrogram (Ward/Euclidean)")
  plot_dendrogram(model, truncate_mode="level", p=3) #top three levels 
  plt.xlabel("Number of points in node (or index of point if no parenthesis).")
  plt.show()

#############################################################################
def DescribeModel(model):
  logging.info(f"clusters: {model.n_clusters_}")
  logging.info(f"leaves: {model.n_leaves_}")
  feature_names_in = model.feature_names_in_ #ndarray of shape (n_features_in_,)
  logging.info(f"feature_names_in: {feature_names_in}")
  children = model.children_ #array-like of shape (n_samples-1,2)
  for row in children:
    logging.info(f"{row[0]}, {row[1]}")
  distances = model.distances_ #array-like of shape (n_nodes-1,)
  logging.info(f"distances: {distances}")


#############################################################################
if __name__=="__main__":
  parser = argparse.ArgumentParser(description="Hierarchical, agglomerative clustering by Scikit-learn", epilog="")
  OPS = ["cluster", "demo", ]
  parser.add_argument("op", choices=OPS, help="OPERATION")
  parser.add_argument("--i", dest="ifile", help="input file, TSV")
  parser.add_argument("--o", dest="ofile", help="output file, TSV")
  parser.add_argument("--o_vis", dest="ofile_vis", default="/tmp/cluster_dendogram.html", help="output file, PNG or HTML")
  parser.add_argument("--scratchdir", default="/tmp")
  parser.add_argument("--idelim", default="\t", help="delim for input TSV")
  parser.add_argument("--odelim", default="\t", help="delim for output TSV")
  parser.add_argument("--iheader", action="store_true", help="input TSV has header")
  parser.add_argument("--oheader", action="store_true", help="output TSV has header")
  parser.add_argument("-v", "--verbose", action="count", default=0)
  args = parser.parse_args()

  logging.basicConfig(format='%(levelname)s:%(message)s', level=(logging.DEBUG if args.verbose>1 else logging.INFO))

  logging.info(f"Scikit-learn version: {sklearn.__version__}")
  logging.info(f"Matplotlib version: {mpl.__version__}")
  logging.info(f"Scipy version: {scipy.__version__}")
  logging.info(f"Numpy version: {np.__version__}")

  t0=time.time()

  if args.op=="demo":
    Demo()
    sys.exit()

  elif args.op=="cluster":
    if args.ifile is None:
      logging.error(f"--ifile required for operation: {args.op}")

  else:
    parser.error(f"Unsupported operation: {args.op}")

  logging.info(f"""Elapsed: {time.strftime('%Hh:%Mm:%Ss', time.gmtime(time.time()-t0))}""")


