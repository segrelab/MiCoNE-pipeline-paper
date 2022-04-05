import pathlib
import sys

from data_extraction import extract_data
from extract_figure6_data import make_process_string, make_prevprocess_string

NI_METHODS = (
    ("dir", "cozine"),
    ("dir", "flashweave"),
    ("dir", "harmonies"),
    ("dir", "mldm"),
    ("dir", "spieceasi"),
    ("dir", "spring"),
    ("corr", "pearson"),
    ("corr", "propr"),
    ("corr", "sparcc"),
    ("corr", "spearman"),
)


def extract_figure5_data(
    input_folder: pathlib.Path, output_folder: pathlib.Path, meta_id_list: list
) -> None:
    # STEP1: Loop through each NI method
    for ni_type, ni_method in NI_METHODS:
        workflow = "network_inference"
        module = "network"
        process = make_process_string((ni_type, ni_method))
        prev_process = make_prevprocess_string(
            DC="dada2",
            CC="remove_bimera",
            TA="naive_bayes(gg_13_8_99)",
            OP="normalize_filter(on)",
            GROUP="group(Genus)",
            NI=ni_method,
        )
        # STEP2: Extract the data
        output_subfolder = output_folder / ni_method
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
    META_ID_LIST = sys.argv[3:]
    OUTPUT_FOLDER = pathlib.Path(f"../../data/figure5/input/{DATASET}")
    extract_figure5_data(INPUT_FOLDER, OUTPUT_FOLDER, META_ID_LIST)
