#!/usr/bin/env python3

import pathlib
import shutil

import click


MAP = {
    "input.1": "input",
    "uchime.1": "open_reference",
    "uchime.2": "closed_reference",
    "uchime.3": "de_novo",
    "uchime.4": "dada2",
    "uchime.5": "deblur",
}


@click.command()
@click.option("--base_dir", help="Location of the directory containing the otus")
@click.option("--output_dir", help="Location of the output directory")
def main(base_dir: str, output_dir: str):
    base_path = pathlib.Path(base_dir)
    output_path = pathlib.Path(output_dir)
    assert output_path.exists()
    glob = "**/otu_table.biom"
    for folder, method_name in MAP.items():
        file = next((base_path / folder).glob(glob))
        shutil.copy(file, str(output_path / f"{method_name}.biom"))


if __name__ == "__main__":
    main()
