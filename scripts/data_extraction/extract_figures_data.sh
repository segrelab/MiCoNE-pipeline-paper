#!/usr/bin/env bash

INPUT_FOLDER="/home/dileep/Documents/Work/MIND/Results/micone_scc_testing/full_pipeline_testing/outputs/outputs"
DATASET="moving_pictures"

python extract_figure2_data.py $INPUT_FOLDER $DATASET
python extract_figure3_data.py $INPUT_FOLDER $DATASET
python extract_figure4_data.py $INPUT_FOLDER $DATASET
python extract_figure5_data.py $INPUT_FOLDER $DATASET
python extract_figure6_data.py $INPUT_FOLDER $DATASET
