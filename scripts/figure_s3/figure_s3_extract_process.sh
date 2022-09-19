#!/bin/bash -l

#$ -l h_rt=10:00:00
#$ -N micone_figure_s3
#$ -P visant
#$ -o figure_s3_outputs.txt
#$ -e figure_s3_errors.txt
#$ -m e
#$ -pe omp 8

INPUT_FOLDER="/rprojectnb/visant/dkishore/FMT/outputs"
DATASET="FMT"
PLATFORM="scc"

# Data extraction
if [ $PLATFORM == "scc" ]; then
  module load miniconda
  conda activate micone-figures-py
fi

cd ../data_extraction/
mkdir -pv ../../data/figure_s3/input/$DATASET
python extract_figure_s3_data.py $INPUT_FOLDER $DATASET "*"

# Data processing
if [ $PLATFORM == "scc" ]; then
  module load miniconda
  conda activate micone-qiime2
fi

cd ../figure_s3/
mkdir -pv ../../data/figure_s3/intermediate/$DATASET
mkdir -pv ../../data/figure_s3/output/$DATASET
# Make trees
python figure_s3_make_trees.py \
  --base_dir ../../data/figure_s3/input/$DATASET \
  --output_dir ../../data/figure_s3/intermediate/$DATASET
# Unweighted unifrac
python -W ignore figure_s3_data.py \
  --trees "../../data/figure_s3/intermediate/$DATASET/trees/**/*.nwk" \
  --otus "../../data/figure_s3/input/$DATASET/**/*_filtered.biom" \
  --weighted False \
  --threshold 10 \
  --output "../../data/figure_s3/output/$DATASET"
# Weighted unifrac
python -W ignore figure_s3_data.py \
  --trees "../../data/figure_s3/intermediate/$DATASET/trees/**/*.nwk" \
  --otus "../../data/figure_s3/input/$DATASET/**/*_filtered.biom" \
  --weighted True \
  --threshold 10 \
  --output "../../data/figure_s3/output/$DATASET"
