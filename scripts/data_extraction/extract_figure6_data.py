import pathlib
from typing import Tuple

from data_extraction import extract_data

DC_METHODS = (
    "closed_reference(gg_97)",
    "open_reference(gg_97)",
    "de_novo",
    "dada2",
    "deblur",
)

CC_METHODS = ("uchime", "remove_bimera")

TA_METHODS = ("blast(ncbi)", "naive_bayes(gg_13_8_99)", "naive_bayes(silva_138_99)")

TAX_LEVEL = "Genus"

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

DEFAULT = {
    "DC": "dada2",
    "CC": "remove_bimera",
    "TA": "naive_bayes(gg_13_8_99)",
    "NI": "consensus",
}


def make_process_string(ni_method: Tuple[str, str]) -> str:
    if ni_method[0] == "dir":
        return "make_network_without_pvalue"
    elif ni_method[0] == "corr":
        return "make_network_with_pvalue"
    else:
        raise ValueError(f"Unknown method {ni_method[0]}")


def make_prevprocess_string(DC: str, CC: str, TA: str, TAX_LEVEL: str, NI: str) -> str:
    prevprocess_string = f"{DC}-{CC}-{TA}-{TAX_LEVEL}-{NI}"
    return prevprocess_string


def extract_step_data(
    step: str, input_folder: pathlib.Path, output_folder: pathlib.Path
):
    workflow = "network_inference"
    module = "network"
    default_dc = DEFAULT["DC"]
    default_cc = DEFAULT["CC"]
    default_ta = DEFAULT["TA"]
    tax_level = TAX_LEVEL

    method_dict = dict()
    method_dict["TAX_LEVEL"] = tax_level
    if step == "DC":
        method_dict["CC"] = default_cc
        method_dict["TA"] = default_ta
        loop_list_1 = DC_METHODS
        loop_list_2 = NI_METHODS
    elif step == "CC":
        method_dict["DC"] = default_dc
        method_dict["TA"] = default_ta
        loop_list_1 = CC_METHODS
        loop_list_2 = NI_METHODS
    elif step == "TA":
        method_dict["DC"] = default_dc
        method_dict["CC"] = default_cc
        loop_list_1 = TA_METHODS
        loop_list_2 = NI_METHODS
    elif step == "NI":
        method_dict["DC"] = default_dc
        method_dict["CC"] = default_cc
        method_dict["TA"] = default_ta
        loop_list_1 = [m[1] for m in NI_METHODS]
        loop_list_2 = NI_METHODS
    else:
        raise ValueError(f"Unsupported step {step}")
    for method in loop_list_1:
        if method != DEFAULT[step]:
            method_dict[step] = method
            output_sub_folder = output_folder / method
            for ni_type, ni_method in loop_list_2:
                if step == "NI" and ni_method != method:
                    continue
                method_dict["NI"] = ni_method
                process = make_process_string((ni_type, ni_method))
                previous_process = make_prevprocess_string(**method_dict)
                extract_data(
                    input_folder,
                    workflow,
                    module,
                    process,
                    previous_process,
                    output_sub_folder,
                )


def extract_figure6_data(
    input_folder: pathlib.Path, output_folder: pathlib.Path
) -> None:
    # STEP1:  Extract DC data
    output_sub_folder = output_folder / "DC"
    extract_step_data("DC", input_folder, output_sub_folder)
    # STEP1:  Extract CC data
    output_sub_folder = output_folder / "CC"
    extract_step_data("CC", input_folder, output_sub_folder)
    # STEP1:  Extract TA data
    output_sub_folder = output_folder / "TA"
    extract_step_data("TA", input_folder, output_sub_folder)
    # STEP1:  Extract NI data
    output_sub_folder = output_folder / "NI"
    extract_step_data("NI", input_folder, output_sub_folder)


if __name__ == "__main__":
    INPUT_FOLDER = pathlib.Path(
        "/home/dileep/Documents/Work/MIND/Results/micone_scc_testing/full_pipeline_testing/outputs/outputs"
    )
    OUTPUT_FOLDER = pathlib.Path("../../data/figure6/input/moving_pictures")
    extract_figure6_data(INPUT_FOLDER, OUTPUT_FOLDER)
