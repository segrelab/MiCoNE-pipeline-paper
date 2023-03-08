#!/usr/bin/env bash

DATASET="EMP"

echo "Processing Figure 6"
rm -f *.pkl
mkdir -pv "../../data/figure6/output/$DATASET"
# NOTE: This requires 8 cpu cores
python figure6_data.py \
  --files "../../data/figure6/input/$DATASET/**/*.json" \
  --level "Genus" \
  --interaction_threshold 0.1 \
  --pvalue_threshold 0.05 \
  --ncpus 8 \
  --output "../../data/figure6/output/$DATASET"
