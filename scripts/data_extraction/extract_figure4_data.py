import pathlib
import sys

from data_extraction import extract_data

TA_METHODS = ("blast(ncbi)", "naive_bayes(gg_13_8_99)", "naive_bayes(silva_138_99)")


def extract_figure4_data(
    input_folder: pathlib.Path, output_folder: pathlib.Path, meta_id_list: list
) -> None:
    # STEP1: Loop through each TA method
    for ta_method in TA_METHODS:
        workflow = "tax_assignment"
        module = ta_method
        process = "taxonomy_tables"
        prev_process = "dada2-remove_bimera"
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
    OUTPUT_FOLDER = pathlib.Path(f"../../data/figure4/input/{DATASET}")
    extract_figure4_data(INPUT_FOLDER, OUTPUT_FOLDER, META_ID_LIST)
