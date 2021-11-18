#!/usr/bin/env python3

import pathlib
import shutil

import click
import pandas as pd
from pandas.core.indexes.base import default_index

DC_processes = {
    "closed_reference",
    "open_reference",
    "de_novo",
    "dada2",
    "deblur",
}

FOLDER = pathlib.Path(
    "/home/dileep/Documents/Work/MIND/Results/micone_scc_testing/full_pipeline_testing/outputs/outputs"
)


def check_if_proctree(folder: pathlib.Path) -> bool:
    flag = False
    for dc_process in DC_processes:
        if folder.stem.startswith(dc_process):
            flag = True
    return flag


def parse_data(folder: pathlib.Path):
    # first level: workflow
    # second level: module with parameter in ()
    # third level: process name
    # fourth level: previous process (does not exist always)
    # fifth level: meta.id
    # sixth level: files
    data = []
    for workflow in folder.iterdir():
        for module in workflow.iterdir():
            for process in module.iterdir():
                if all(map(check_if_proctree, process.iterdir())):
                    # then it is list of previous processes
                    for previous_process in process.iterdir():
                        for meta_id in previous_process.iterdir():
                            files = list(meta_id.iterdir())
                            data_item = {
                                "workflow": workflow.stem,
                                "module": module.stem,
                                "process": process.stem,
                                "previous_process": previous_process.stem,
                                "meta_id": meta_id.stem,
                                "files": files,
                            }
                            assert all(map(lambda x: x.is_file(), files))
                            data.append(data_item)
                else:
                    previous_process = ""
                    for meta_id in process.iterdir():
                        files = list(meta_id.iterdir())
                        data_item = {
                            "workflow": workflow.stem,
                            "module": module.stem,
                            "process": process.stem,
                            "previous_process": previous_process,
                            "meta_id": meta_id.stem,
                            "files": files,
                        }
                        assert all(map(lambda x: x.is_file(), files))
                        data.append(data_item)
    return pd.DataFrame(data)


@click.command()
@click.option("--folder", help="Path to the pipeline output", type=pathlib.Path)
@click.option("--workflow")
@click.option("--module")
@click.option("--process")
@click.argument("output_directory", type=pathlib.Path)
def extract_data(
    folder: pathlib.Path,
    workflow: str,
    module: str,
    process: str,
    output_directory: pathlib.Path,
) -> None:
    df = parse_data(folder)
    df_sub = df[
        (df.workflow == workflow) & (df.module == module) & (df.process == process)
    ]
    output_directory.mkdir(parents=True, exist_ok=True)
    for _, df_row in df_sub.iterrows():
        if df_row.previous_process:
            directory = output_directory / f"{df_row.previous_process}/{df_row.meta_id}"
        else:
            directory = output_directory / f"{df_row.meta_id}"
        directory.mkdir(parents=True, exist_ok=True)
        for file in df_row.files:
            file_path_old = pathlib.Path(file)
            file_path_new = directory / file_path_old.name
            print(f"Copying {file_path_old} -> {file_path_new}")
            shutil.copy(file_path_old, file_path_new)


if __name__ == "__main__":
    extract_data()
