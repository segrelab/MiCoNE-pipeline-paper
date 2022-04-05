#!/bin/bash -l

#$ -l h_rt=4:00:00
#$ -N micone_data_extraction
#$ -P visant
#$ -o extraction_outputs.txt
#$ -e extraction_errors.txt
#$ -m e
#$ -pe omp 4

# TODO: Change this before running
INPUT_FOLDER="/rprojectnb/visant/dkishore/FMT/outputs"
DATASET="FMT"
PLATFORM="scc"

if [ $PLATFORM == "scc" ]; then
  module load miniconda
  conda activate micone-figures-py
fi

python extract_figure2_data.py $INPUT_FOLDER $DATASET "fmt-control"
python extract_figure3_data.py $INPUT_FOLDER $DATASET
python extract_figure4_data.py $INPUT_FOLDER $DATASET
python extract_figure5_data.py $INPUT_FOLDER $DATASET "fmt-control"
python extract_figure6_data.py $INPUT_FOLDER $DATASET "fmt-control" "fmt-autism"
