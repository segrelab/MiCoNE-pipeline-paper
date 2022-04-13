# /usr/bin/env python3


import pathlib
import shutil

### NoRTA
network_files = list(pathlib.Path("../data/figure6/input/norta/").glob("**/*.json"))
datasets = set(
    pathlib.Path(
        "/home/dileep/Documents/Work/MIND/synthetic_interactions/data/norta/input/"
    ).iterdir()
)
dataset_map = {v.stem: v for v in datasets}
for network_file in network_files:
    dir = network_file.parent
    dir_name = network_file.parent.stem
    assert dir_name in dataset_map
    input_file = dataset_map[dir_name] / "interaction_matrix.tsv"
    output_file = dir / "interaction_matrix.tsv"
    shutil.copy(input_file, output_file)

### Seqtime
network_files = list(pathlib.Path("../data/figure6/input/seqtime/").glob("**/*.json"))
datasets = set(
    pathlib.Path(
        "/home/dileep/Documents/Work/MIND/synthetic_interactions/data/seqtime/input/"
    ).iterdir()
)
dataset_map = {v.stem: v for v in datasets}
for network_file in network_files:
    dir = network_file.parent
    dir_name = network_file.parent.stem
    assert dir_name in dataset_map
    input_file = dataset_map[dir_name] / "interaction_matrix.tsv"
    output_file = dir / "interaction_matrix.tsv"
    shutil.copy(input_file, output_file)
