#!/usr/bin/env python3

import json
import pathlib

import numpy as np
import pandas as pd
import rcca
from sklearn.cross_decomposition import CCA, PLSCanonical
from sklearn.preprocessing import OneHotEncoder

import statsmodels.formula.api as smf
from statsmodels.stats.anova import anova_lm


def read_correlations(corr_table_file: pathlib.Path) -> pd.DataFrame:
    corr_table = pd.read_table(corr_table_file, index_col=0, sep="\t")
    return corr_table


def read_metadata(metadata_file: pathlib.Path) -> dict:
    with open(metadata_file) as fid:
        metadata = json.load(fid)
    return metadata


def create_matrices(corr_table: pd.DataFrame, metadata: dict):
    # NOTE: X = nxq and Y = nxp
    Y_full = corr_table.values.T
    n = Y_full.shape[0]
    # NOTE: We have 3 higher variables
    # DC = 5 # TA = 3 # OP = 2
    # Totally, 10 variables after one-hot-encoding
    X_features = []
    # Ensure order is of samples is correct
    for ind in range(n):
        X_features.append(metadata[str(ind + 1)])
    enc = OneHotEncoder()
    enc.fit(X_features)
    X = enc.transform(X_features).toarray().astype(int)
    Y_var = np.var(Y_full, axis=0)
    max_var_inds = np.argsort(Y_var)[-1000:]
    Y = Y_full[:, max_var_inds]
    assert X.shape[0] == Y.shape[0]
    return X, Y, enc


# TODO: These functions should return variances instead of CCA objects
def perform_sklearn_cca(X: np.ndarray, Y: np.ndarray, method: str = "CCA"):
    assert X.shape[0] == Y.shape[0]
    n, p, q = X.shape[0], X.shape[1], Y.shape[1]
    n_components = min(n, p, q)
    if method == "CCA":
        cca = CCA(n_components=4, scale=False)
    elif method == "PLSCanonical":
        cca = PLSCanonical(n_components=4, scale=False)
    else:
        raise ValueError(f"Unsupport method: {method}")
    cca.fit(X, Y)
    return cca


def perform_pyrcca_cca(X: np.ndarray, Y: np.ndarray):
    assert X.shape[0] == Y.shape[0]
    n, p, q = X.shape[0], X.shape[1], Y.shape[1]
    n_components = min(n, p, q)
    cca = rcca.CCA(kernelcca=False, reg=1e4, numCC=n_components)
    cca.train([X, Y])
    return cca


def calculate_sklearn_var(cca: CCA, X: np.ndarray, Y: np.ndarray, X_encoder):
    shared_var = cca.score(X, Y)  # Return R^2
    return shared_var


def calculate_pyrcca_var(cca: rcca.CCA, X: np.ndarray, Y: np.ndarray, X_encoder):
    """Calculate the variance in CCA using canonical loadings"""
    var = cca.compute_ev([X, Y])  # dims: components x features
    # This gives us how much of variance of each feature is explained by each component
    # What we want to do now is get the ev of Y (var[1]) for each component
    Y_ev = var[1]
    Y_var_percomponent = Y_ev.sum(axis=1)  # total variance explained by each component
    X_ev = var[0]
    X_var = X_ev.sum(axis=0)  # total variance explained by each feature
    X_features = [name.split("_", 1) for name in X_encoder.get_feature_names()]
    var_contribution = dict(zip(list(X_var), X_features))
    # TODO: Calculate canonical loadings
    return var_contribution


if __name__ == "__main__":
    DATA_DIR = pathlib.Path("../../data/figure2/")
    corr_table_file = DATA_DIR / "corr_table.tsv"
    metadata_file = DATA_DIR / "metadata.json"
    # Read data
    corr_table = read_correlations(corr_table_file)
    metadata = read_metadata(metadata_file)
    # Create X and Y vectors
    X, Y, X_encoder = create_matrices(corr_table, metadata)
    # Perform CCA
    cca_sklearn = perform_sklearn_cca(X, Y)
    cca_pyrcca = perform_pyrcca_cca(X, Y)
    # Calculate variance
    # TODO: var_sklearn = calculate_sklearn_var(cca_sklearn, X, Y)
    var_pyrcca = calculate_pyrcca_var(cca_pyrcca, X, Y, X_encoder)
    X_r, Y_r = cca_pyrcca.comps  # samples x n_components
    # TODO: Is this even possible without a formula?
    # model = smf.ols(formula, data=table).fit()
    # anova = anova_lm(model, typ=2)
