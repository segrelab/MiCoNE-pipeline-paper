#!/usr/bin/env python

import hashlib
import pathlib
import pickle
import multiprocessing as mp
from typing import Optional, Tuple

import click
from micone import Network
import numpy as np
import pandas as pd
from sklearn.decomposition import PCA, SparsePCA
from sklearn.manifold import TSNE
from statsmodels.formula.api import ols
import statsmodels.api as sm
import tqdm
from tqdm_multiprocess import TqdmMultiProcessPool

import warnings

warnings.filterwarnings("ignore")

CORR = [
    "sparcc",
    "propr",
    "spearman",
    "pearson",
]

DIR = [
    "flashweave",
    "mldm",
    "spieceasi",
    "cozine",
    "harmonies",
    "spring",
]


def create_edge_df(network: Network, hash: str) -> Optional[pd.DataFrame]:
    graph = network.graph
    id_name_map = dict()
    edge_data = []
    if len(graph.edges):
        for node, ndata in graph.nodes(data=True):
            id_name_map[node] = ndata["lineage"]
        for source, target, edata in graph.edges(data=True):
            source_name = id_name_map[source]
            target_name = id_name_map[target]
            ename = f"{source_name}-{target_name}"
            edge_data.append({"edge": ename, hash: edata["weight"]})
        edge_df = pd.DataFrame(edge_data).drop_duplicates(subset=["edge"])
        edge_df.set_index("edge", inplace=True)
        # edge_df[hash] = edge_df[hash] / np.abs(edge_df[hash]).max()
        return edge_df.T
    else:
        return None


def parse_data(
    file_path: pathlib.Path,
    interaction_threshold: float,
    pvalue_threshold: float,
    tqdm_func,
    global_tqdm,
) -> Tuple[Optional[dict], Optional[pd.DataFrame]]:
    # HEADER = ["DC", "CC", "TA", "OP", "NI"]
    HEADER = ["DC", "CC", "TA", "TL", "NI"]
    process_string = file_path.parent.parent.stem
    hash = hashlib.md5(process_string.encode("utf-8")).hexdigest()
    processes = process_string.split("-")
    x_dataitem = dict(zip(HEADER, processes))
    x_dataitem["hash"] = hash
    network = Network.load_json(str(file_path))
    network.interaction_threshold = interaction_threshold
    network.pvalue_threshold = pvalue_threshold
    filtered_network = network.filter(pvalue_filter=True, interaction_filter=True)
    # Create edge list
    y_dataitem = create_edge_df(filtered_network, hash)
    # tqdm_func.update()
    global_tqdm.update()
    if y_dataitem is None:
        return None, None
    return x_dataitem, y_dataitem


def perform_anova(X: pd.DataFrame, Y: pd.DataFrame) -> dict:
    anova_dict = dict()
    for component in Y.columns:
        data = [
            {
                "Y": Y.loc[i, component],
                "DC": X.loc[i, "DC"],
                "CC": X.loc[i, "CC"],
                "TA": X.loc[i, "TA"],
                # "OP": X.loc[i, "OP"],
                "NI": X.loc[i, "NI"],
            }
            for i in Y.index
        ]
        df = pd.DataFrame(data)
        # lm = ols("Y ~ C(DC) + C(TA) + C(OP)", data=df).fit()
        lm = ols("Y ~ C(DC) + C(CC) + C(TA) + C(NI)", data=df).fit()
        anova_dict[component] = sm.stats.anova_lm(lm, typ=2)
    return anova_dict


def normalize_anova(anova_dict: dict, pca: PCA) -> list:
    var_ratio = pca.explained_variance_ratio_
    assert np.isclose(sum(var_ratio), 1)
    variance_list = []
    for component in anova_dict:
        anova_dict[component]["mean_sq"] = (
            anova_dict[component]["sum_sq"] / anova_dict[component]["df"]
        )
        variance = anova_dict[component]["mean_sq"]
        ratio = var_ratio[component]
        variance_list.append(variance * ratio)
    return variance_list


def error_callback(result):
    print("Error!")


def done_callback(result):
    pass


@click.command()
@click.option(
    "--files", help="The path to the network files containing the glob pattern"
)
@click.option(
    "--level", default="Genus", help="The taxonomy level to use for the data processing"
)
@click.option(
    "--interaction_threshold",
    default=0.1,
    type=float,
    help="The interaction threshold to apply",
)
@click.option(
    "--pvalue_threshold",
    default=0.05,
    type=float,
    help="The pvalue threshold to apply",
)
@click.option("--ncpus", default=4, type=int, help="The number of cpus to use")
@click.option("--output", default=".", help="The path to the output directory")
def main(
    files: str,
    level: str,
    interaction_threshold: float,
    pvalue_threshold: float,
    ncpus: int,
    output: str,
):
    output_path = pathlib.Path(output)
    assert output_path.exists()

    base_dir, glob = files.split("*", 1)
    glob = "*" + glob
    base_path = pathlib.Path(base_dir)
    file_paths = [
        f for f in base_path.glob(glob) if level in f.parent.parent.stem.split("-")
    ]

    # Multiprocessing setup
    pool = TqdmMultiProcessPool(ncpus)
    tasks = [
        (parse_data, (file_path, interaction_threshold, pvalue_threshold))
        for file_path in file_paths
    ]
    task_count = len(tasks)

    print("Step1: Compiling the X and Y matrices from networks")
    step_1_2_pickle = pathlib.Path("step_1_2.pkl")
    if step_1_2_pickle.exists():
        with open(step_1_2_pickle, "rb") as fid:
            x_df = pickle.load(fid)
            y_df = pickle.load(fid)
    else:
        with tqdm.tqdm(total=task_count, dynamic_ncols=True) as global_progress:
            global_progress.set_description("global")
            # Step1: For each file note down all the `HEADER` categories and get edge list
            # Step2: Compile the header values and edge lists using join
            results = pool.map(global_progress, tasks, error_callback, done_callback)
        print("Step2a: Creating the dataframes using join")
        x_all, y_all = zip(*results)
        x_data = [item for item in x_all if item is not None]
        y_data = [item for item in y_all if item is not None]
        x_df: pd.DataFrame = pd.DataFrame(x_data).set_index("hash")
        y_df = pd.concat(y_data, axis=0, join="outer")
        assert x_df.shape[0] == y_df.shape[0]
        print("Step2b: Saving the data")
        x_df.to_csv(output_path / "x.csv", index=True, sep=",")
        y_df.to_csv(output_path / "y.csv", index=True, sep=",")
        with open(step_1_2_pickle, "wb") as fid:
            pickle.dump(x_df, fid)
            pickle.dump(y_df, fid)

    print(x_df.head())
    print(y_df.head())

    # Step3: Perform PCA on the edge matrix (Y) and then transform Y to PCA coordinates
    print("Step 3: Performing PCA on Y")
    step_3_pickle = pathlib.Path("step_3.pkl")
    if step_3_pickle.exists():
        with open(step_3_pickle, "rb") as fid:
            y_reduced = pickle.load(fid)
            y_reduced2 = pickle.load(fid)
            pca = pickle.load(fid)
    else:
        y_df.fillna(0.0, inplace=True)
        # TODO: Set variance to be 0.95 using n_components=0.95
        pca = PCA()
        pca2 = PCA(n_components=2)
        tsne = TSNE(n_components=2)
        pca.fit(y_df)
        pca2.fit(y_df)
        y_reduced = pd.DataFrame(pca.transform(y_df), index=y_df.index)
        y_reduced2 = pd.DataFrame(pca2.transform(y_df), index=y_df.index)
        y_reduced_tsne = pd.DataFrame(tsne.fit_transform(y_df), index=y_df.index)
        y_reduced.to_csv(output_path / "y_reduced.csv", index=True, sep=",")
        y_reduced2.to_csv(output_path / "y_reduced2.csv", index=True, sep=",")
        y_reduced_tsne.to_csv(output_path / "y_reduced_tsne.csv", index=True, sep=",")
        with open(step_3_pickle, "wb") as fid:
            pickle.dump(y_reduced, fid)
            pickle.dump(y_reduced2, fid)
            pickle.dump(pca, fid)

    print(y_reduced.head())

    # Step4: Perform ANOVA and normalize by total variance
    print("Step 4: Performing ANOVA and calculating total variance")
    step_4_pickle = pathlib.Path("step_4.pkl")
    if step_4_pickle.exists():
        with open(step_4_pickle, "rb") as fid:
            variance_list = pickle.load(fid)
            percentage_variance = pickle.load(fid)
    else:
        anova_dict = perform_anova(x_df, y_reduced)
        variance_list = normalize_anova(anova_dict, pca)
        total_variance = sum(variance_list)
        percentage_variance = total_variance / total_variance.sum() * 100
        percentage_variance.to_csv(
            output_path / "percentage_variance.csv", index=True, sep=","
        )
        with open(step_4_pickle, "wb") as fid:
            pickle.dump(variance_list, fid)
            pickle.dump(percentage_variance, fid)

    print(percentage_variance)


if __name__ == "__main__":
    main()
