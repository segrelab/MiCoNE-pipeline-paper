#!/usr/bin/env python3

import click
import pandas as pd
from sklearn.decomposition import PCA


def calculate_pca(table: pd.DataFrame, components: int = 2):
    X = table.values.T
    pca = PCA(n_components=components)
    X_pca = pca.fit_transform(X)
    return pca, X_pca


@click.command()
@click.option("--corr_table", help="The file containing the correlation table")
def main(corr_table):
    table = pd.read_table(corr_table, index_col=0)
    pca, X_pca = calculate_pca(table)


if __name__ == "__main__":
    main()
