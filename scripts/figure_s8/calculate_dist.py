#!/usr/bin/env python3

from itertools import product
import pathlib

import networkx as nx
from networkx.algorithms.similarity import graph_edit_distance
import numpy as np
import pandas as pd


def get_similarity(graph1, graph2):
    # NOTE: https://graph-tool.skewed.de/static/doc/topology.html?highlight=similarity#contents
    graph1_nodes = list(graph1.nodes)
    graph2_nodes = list(graph2.nodes)
    nodes = list(set(graph1_nodes) | set(graph2_nodes))
    node_dict = dict(zip(nodes, range(len(nodes))))
    n = len(nodes)
    adj1 = np.zeros((n, n), dtype=np.float)
    for u, v, edata in graph1.edges(data=True):
        u_ind = node_dict[u]
        v_ind = node_dict[v]
        adj1[u_ind, v_ind] = edata["weight"]
        adj1[v_ind, u_ind] = edata["weight"]
    adj2 = np.zeros((n, n), dtype=np.float)
    for u, v, edata in graph2.edges(data=True):
        u_ind = node_dict[u]
        v_ind = node_dict[v]
        adj2[u_ind, v_ind] = edata["weight"]
        adj2[v_ind, u_ind] = edata["weight"]
    # E = sum(n(graph1_edges), n(graph2_edges))
    E = n * n
    # d = sum(|graph1_edges-graph2_edges|)
    mismatch = np.ones((n, n), dtype=np.int)
    for u_ind, v_ind in product(range(n), range(n)):
        w1, w2 = adj1[u_ind, v_ind], adj2[u_ind, v_ind]
        if (w1 * w2) >= 0:
            mismatch[u_ind, v_ind] = 0
    d = mismatch.sum()
    # S = E - d
    S = (E - d) / E
    return S


def get_hamming_dist(graph1, graph2, sign=True):
    adjmat1 = nx.to_numpy_matrix(graph1)
    adjmat2 = nx.to_numpy_matrix(graph2)
    if sign:
        adjmat1[adjmat1 < 0] = -1
        adjmat1[adjmat1 > 0] = 1
        adjmat2[adjmat2 < 0] = -1
        adjmat2[adjmat2 > 0] = 1
        dtype = int
    else:
        dtype = bool
    return np.count_nonzero(adjmat1.astype(dtype) != adjmat2.astype(dtype)) // 2


def main(files):
    methods = [file.stem for file in files]
    cols = ["method1", "method2", "similarity"]
    method_combs = list(product(methods, methods))
    n_cols = len(cols)
    n_rows = len(method_combs)
    data_list = []
    for file1, file2 in product(files, files):
        name1 = file1.stem
        name2 = file2.stem
        graph1 = nx.read_gml(file1)
        graph2 = nx.read_gml(file2)
        print(f"Calculating similarity between {name1} and {name2}")
        # Need to merge the graphs before
        # NOTE: We need to normalize this somehow
        dist = get_similarity(graph1, graph2)
        data_list.append({"method1": name1, "method2": name2, "similarity": dist})
    df = pd.DataFrame(data_list)
    assert len(df.columns) == n_cols
    assert len(df.index) == n_rows
    df.to_csv("similarity.csv")


if __name__ == "__main__":
    FILES = list(pathlib.Path(".").glob("*.gml"))
    main(FILES)
