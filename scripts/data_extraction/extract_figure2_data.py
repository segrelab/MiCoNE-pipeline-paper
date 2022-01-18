import pathlib
import sys

from data_extraction import extract_data


def extract_step_data(
    process: str, input_folder: pathlib.Path, output_folder: pathlib.Path
) -> None:
    workflow = "network_inference"
    module = "network"
    extract_data(input_folder, workflow, module, process, "", output_folder)


def extract_figure2_data(
    input_folder: pathlib.Path, output_folder: pathlib.Path
) -> None:
    # STEP1: Extract make_network_with_pvalue
    extract_step_data("make_network_with_pvalue", input_folder, output_folder)
    # STEP2: Extract make_network_without_pvalue
    extract_step_data("make_network_without_pvalue", input_folder, output_folder)


if __name__ == "__main__":
    INPUT_FOLDER = pathlib.Path(sys.argv[1])
    DATASET = sys.argv[2]
    OUTPUT_FOLDER = pathlib.Path(f"../../data/figure2/input/{DATASET}")
    extract_figure2_data(INPUT_FOLDER, OUTPUT_FOLDER)
