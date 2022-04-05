import pathlib
import sys
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

OP_METHODS = ("normalize_filter(on)", "normalize_filter(off)")

GROUP_LEVEL = "group(Genus)"

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
    "OP": "normalize filter(on)",
    "NI": "consensus",
}


def make_process_string(ni_method: Tuple[str, str]) -> str:
    if ni_method[0] == "dir":
        return "make_network_without_pvalue"
    elif ni_method[0] == "corr":
        return "make_network_with_pvalue"
    else:
        raise ValueError(f"Unknown method {ni_method[0]}")


def make_prevprocess_string(
    DC: str, CC: str, TA: str, OP: str, GROUP: str, NI: str
) -> str:
    prevprocess_string = f"{DC}-{CC}-{TA}-{OP}-{GROUP}-{NI}"
    return prevprocess_string


def extract_step_data(
    step: str,
    input_folder: pathlib.Path,
    output_folder: pathlib.Path,
    meta_id_list: list,
):
    workflow = "network_inference"
    module = "network"
    default_dc = DEFAULT["DC"]
    default_cc = DEFAULT["CC"]
    default_ta = DEFAULT["TA"]
    default_op = DEFAULT["OP"]
    group_level = GROUP_LEVEL

    method_dict = dict()
    method_dict["GROUP"] = group_level
    if step == "default":
        method_dict["DC"] = default_dc
        method_dict["CC"] = default_cc
        method_dict["TA"] = default_ta
        method_dict["OP"] = default_op
        loop_list_1 = DC_METHODS
        loop_list_2 = NI_METHODS
    elif step == "DC":
        method_dict["CC"] = default_cc
        method_dict["TA"] = default_ta
        method_dict["OP"] = default_op
        loop_list_1 = DC_METHODS
        loop_list_2 = NI_METHODS
    elif step == "CC":
        method_dict["DC"] = default_dc
        method_dict["TA"] = default_ta
        method_dict["OP"] = default_op
        loop_list_1 = CC_METHODS
        loop_list_2 = NI_METHODS
    elif step == "TA":
        method_dict["DC"] = default_dc
        method_dict["CC"] = default_cc
        method_dict["OP"] = default_op
        loop_list_1 = TA_METHODS
        loop_list_2 = NI_METHODS
    elif step == "OP":
        method_dict["DC"] = default_dc
        method_dict["CC"] = default_cc
        method_dict["TA"] = default_ta
        loop_list_1 = OP_METHODS
        loop_list_2 = NI_METHODS
    elif step == "NI":
        method_dict["DC"] = default_dc
        method_dict["CC"] = default_cc
        method_dict["TA"] = default_ta
        method_dict["OP"] = default_op
        loop_list_1 = [m[1] for m in NI_METHODS]
        loop_list_2 = NI_METHODS
    else:
        raise ValueError(f"Unsupported step {step}")
    if step != "default":
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
                        meta_id_list,
                    )
    else:
        output_sub_folder = output_folder / "default"
        for ni_type, ni_method in loop_list_2:
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
                meta_id_list,
            )


def extract_figure6_data(
    input_folder: pathlib.Path, output_folder: pathlib.Path, meta_id_list: list
) -> None:
    # STEP1: Extract default data
    output_sub_folder = output_folder / "default"
    extract_step_data("default", input_folder, output_sub_folder, meta_id_list)
    # STEP2:  Extract DC data
    output_sub_folder = output_folder / "DC"
    extract_step_data("DC", input_folder, output_sub_folder, meta_id_list)
    # STEP3:  Extract CC data
    output_sub_folder = output_folder / "CC"
    extract_step_data("CC", input_folder, output_sub_folder, meta_id_list)
    # STEP4:  Extract TA data
    output_sub_folder = output_folder / "TA"
    extract_step_data("TA", input_folder, output_sub_folder, meta_id_list)
    # STEP5:  Extract OP data
    output_sub_folder = output_folder / "OP"
    extract_step_data("OP", input_folder, output_sub_folder, meta_id_list)
    # STEP6:  Extract NI data
    output_sub_folder = output_folder / "NI"
    extract_step_data("NI", input_folder, output_sub_folder, meta_id_list)


if __name__ == "__main__":
    INPUT_FOLDER = pathlib.Path(sys.argv[1])
    DATASET = sys.argv[2]
    META_ID_LIST = tuple(sys.argv[3:])
    OUTPUT_FOLDER = pathlib.Path(f"../../data/figure6/input/{DATASET}")
    extract_figure6_data(INPUT_FOLDER, OUTPUT_FOLDER, META_ID_LIST)
