#!/bin/bash -l

#$ -l h_rt=4:00:00
#$ -N micone_network_metrics
#$ -P visant
#$ -o metrics_outputs.txt
#$ -e metrics_errors.txt
#$ -m e
#$ -pe omp 8

PLATFORM="scc"
DATASET="FMT"

if [ $PLATFORM == "scc" ]; then
  module load miniconda
  conda activate micone-figures-py
fi

# Network metrics
echo "Processing network metrics"
rm -f *.pkl
mkdir -pv "../../data/network_metrics/output/$DATASET"
# NOTE: This requires 8 cpu cores
python calculate_network_metrics.py \
  --files "../../data/figure2/input/$DATASET/**/*.json" \
  --level "Genus" \
  --interaction_threshold 0.1 \
  --pvalue_threshold 0.05 \
  --ncpus 8 \
  --output "../../data/network_metrics/output/$DATASET"
