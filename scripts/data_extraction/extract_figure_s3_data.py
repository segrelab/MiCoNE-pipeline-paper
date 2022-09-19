import pathlib
import sys

from data_extraction import extract_data

CC_METHODS = ("remove_bimera", "uchime")
DC_METHODS = (
    "closed_reference(gg_97)",
    "open_reference(gg_97)",
    "de_novo",
    "dada2",
    "deblur",
)


def extract_figure_s3_data(
    input_folder: pathlib.Path, output_folder: pathlib.Path, meta_id_list: list
) -> None:
    # STEP1: Loop through each CC method
    for cc_method in CC_METHODS:
        workflow = "denoise_cluster"
        module = cc_method
        process = "filtered_output"
        for dc_method in DC_METHODS:
            prev_process = dc_method
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
    OUTPUT_FOLDER = pathlib.Path(f"../../data/figure_s3/input/{DATASET}")
    extract_figure_s3_data(INPUT_FOLDER, OUTPUT_FOLDER, META_ID_LIST)
