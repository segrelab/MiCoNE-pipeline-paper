#!/usr/bin/env bash

echo "Calculating data for norta"
python -W ignore figure5_data.py \
  --files "../../data/figure5/input/norta/**/*.json" \
  --interaction_threshold 0.1 \
  --pvalue_threshold 0.05 \
  --sign False \
  --subset_methods True \
  --output "../../data/figure5/output/norta"

echo "Calculating data for seqtime"
python -W ignore figure5_data.py \
  --files "../../data/figure5/input/seqtime/**/*.json" \
  --interaction_threshold 0.1 \
  --pvalue_threshold 0.05 \
  --sign False \
  --subset_methods True \
  --output "../../data/figure5/output/seqtime"
