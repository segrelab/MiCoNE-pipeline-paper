#!/usr/bin/env bash

#$ -l h_rt=4:00:00
#$ -N micone_data_extraction
#$ -P visant
#$ -o extraction_outputs.txt
#$ -e extraction_errors.txt
#$ -m e
#$ -pe omp 4

# TODO: Change this before running
INPUT_FOLDER="/home/dileep/Documents/Work/MIND/Results/micone_scc_testing/full_pipeline_testing/outputs/outputs"
DATASET="moving_pictures"
PLATFORM="local"

if [ $PLATFORM == "scc" ]; then
  module load miniconda
  conda activate micone-figures-py
fi

python extract_figure2_data.py $INPUT_FOLDER $DATASET
python extract_figure3_data.py $INPUT_FOLDER $DATASET
python extract_figure4_data.py $INPUT_FOLDER $DATASET
python extract_figure5_data.py $INPUT_FOLDER $DATASET
python extract_figure6_data.py $INPUT_FOLDER $DATASET
