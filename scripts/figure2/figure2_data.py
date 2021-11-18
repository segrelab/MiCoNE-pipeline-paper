#!/usr/bin/env python

import pathlib

import pandas as pd
from ..data_extraction import extract_data, FOLDER

CORR_processes = {
    "sparcc",
    "propr",
    "spearman",
    "pearson",
}

DIR_proceses = {
    "flashweave",
    "mldm",
    "spieceasi",
}


def main(df: pd.DataFrame):
    df_sub = df[(df.workflow == "network_inference")]
    print(df_sub.files)


if __name__ == "__main__":
    df = extract_data(FOLDER)
    main(df)
