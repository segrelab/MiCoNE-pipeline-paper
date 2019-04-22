#!/usr/bin/env python3

import pathlib
import shutil

import click


@click.command()
@click.option("--base_dir", help="Location of the directory containing the trees")
@click.option("--output_dir", help="Location of the output directory")
def main(base_dir: str, output_dir: str):
    base_path = pathlib.Path(base_dir)
    output_path = pathlib.Path(output_dir)
    assert output_path.exists()
    glob = "**/*.nwk"
    for file in base_path.glob(glob):
        name = file.parent.parent.stem
        shutil.copy(str(file), str(output_path / f"{name}.nwk"))


if __name__ == "__main__":
    main()
