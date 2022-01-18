import pathlib

from data_extraction import extract_data

DC_METHODS = (
    "closed_reference(gg_97)",
    "open_reference(gg_97)",
    "de_novo",
    "dada2",
    "deblur",
)


def extract_figure3_data(
    input_folder: pathlib.Path, output_folder: pathlib.Path
) -> None:
    # STEP1: Loop through each DC method
    for dc_method in DC_METHODS:
        workflow = "denoise_cluster"
        module = dc_method
        process = "hashed_output"
        # STEP2: Extract the data
        output_subfolder = output_folder / module
        extract_data(input_folder, workflow, module, process, "", output_subfolder)


if __name__ == "__main__":
    INPUT_FOLDER = pathlib.Path(
        "/home/dileep/Documents/Work/MIND/Results/micone_scc_testing/full_pipeline_testing/outputs/outputs"
    )
    OUTPUT_FOLDER = pathlib.Path("../../data/figure3/input/moving_pictures")
    extract_figure3_data(INPUT_FOLDER, OUTPUT_FOLDER)
