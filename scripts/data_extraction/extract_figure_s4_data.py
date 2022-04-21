import pathlib
import sys

from data_extraction import extract_data

CC_METHODS = ("remove_bimera", "uchime")


def extract_figure_s4_data(
    input_folder: pathlib.Path, output_folder: pathlib.Path, meta_id_list: list
) -> None:
    # STEP1: Loop through each TA method
    for cc_method in CC_METHODS:
        workflow = "denoise_cluster"
        module = cc_method
        process = "filtered_output"
        # TODO: We need to loop over all dc methods
        # TODO: We also need to change the folder names to dada2-remove_bimera or something
        # for the tree algorithm
        prev_process = "dada2"
        # STEP2: Extract the data
        output_subfolder = output_folder / module
        extract_data(
            input_folder,
            workflow,
            module,
            process,
            prev_process,
            output_subfolder,
            meta_id_list,
        )


if __name__ == "__main__":
    INPUT_FOLDER = pathlib.Path(sys.argv[1])
    DATASET = sys.argv[2]
    META_ID_LIST = tuple(sys.argv[3:])
    OUTPUT_FOLDER = pathlib.Path(f"../../data/figure_s4/input/{DATASET}")
    extract_figure_s4_data(INPUT_FOLDER, OUTPUT_FOLDER, META_ID_LIST)
