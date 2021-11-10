#!/usr/bin/env python3

import pathlib
import json

import numpy as np
import pandas as pd
from sklearn.decomposition import PCA, SparsePCA
from statsmodels.formula.api import ols
import statsmodels.api as sm


def read_correlations(corr_table_file: pathlib.Path) -> pd.DataFrame:
    corr_table = pd.read_table(corr_table_file, index_col=0, sep="\t")
    corr_table.index.name = "links"
    return corr_table


def create_ydf(corr_table: pd.DataFrame) -> pd.DataFrame:
    # NOTE: X = nxq and Y = nxp
    Y_full = corr_table.T
    # Y_var = np.var(Y_full, axis=0)
    # max_var_inds = np.argsort(Y_var)[-1000:]
    # Y = Y_full[:, max_var_inds]
    return Y_full


def read_metadata(metadata_file: pathlib.Path) -> dict:
    with open(metadata_file) as fid:
        metadata = json.load(fid)
    return metadata


def create_xdf(metadata: dict) -> pd.DataFrame:
    # NOTE: X = nxq and Y = nxp
    # NOTE: We have 3 factors
    # DC = 5 # TA = 3 # OP = 2
    # Totally, 10 variables after one-hot-encoding
    X = pd.DataFrame(metadata, index=["DC", "TA", "OP"])
    return X


def perform_PCA(Y: pd.DataFrame) -> PCA:
    pca = PCA()
    pca.fit(Y)
    return pca


def perform_anova(X: pd.DataFrame, Y: pd.DataFrame) -> dict:
    anova_dict = dict()
    for component in Y.columns:
        data = [
            {
                "Y": Y.loc[i, component],
                "DC": X.loc["DC", i],
                "TA": X.loc["TA", i],
                "OP": X.loc["OP", i],
            }
            for i in Y.index
        ]
        df = pd.DataFrame(data)
        lm = ols("Y ~ C(DC) + C(TA) + C(OP)", data=df).fit()
        anova_dict[component] = sm.stats.anova_lm(lm, typ=2)
    return anova_dict


def normalize_anova(anova_dict: dict, pca: PCA) -> list:
    var_ratio = pca.explained_variance_ratio_
    assert sum(var_ratio) == 1
    variance_list = []
    for component in anova_dict:
        variance = anova_dict[component]["sum_sq"]
        ratio = var_ratio[component]
        variance_list.append(variance * ratio)
    return variance_list


if __name__ == "__main__":
    DATA_DIR = pathlib.Path("../../data/figure2/")
    corr_table_file = DATA_DIR / "corr_table.tsv"
    metadata_file = DATA_DIR / "metadata.json"
    # Read data
    corr_table = read_correlations(corr_table_file)
    metadata = read_metadata(metadata_file)
    # Create X and Y vectors
    Y = create_ydf(corr_table)
    X = create_xdf(metadata)
    pca = perform_PCA(Y)
    Y_red = pd.DataFrame(pca.transform(Y), index=Y.index)
    anova_dict = perform_anova(X, Y_red)
    variance_list = normalize_anova(anova_dict, pca)
    total_variance = sum(variance_list)
    percentage_variance = total_variance / total_variance.sum() * 100
    print(percentage_variance)
