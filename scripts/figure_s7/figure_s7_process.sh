#!/usr/bin/env bash

cd ../figure6/
rm -f *.pkl
mkdir -pv "../../data/figure_s7/output/seqtime"
python -W ignore figure6_data.py \
  --files "../../data/figure6/input/seqtime/**/*.json" \
  --interaction_threshold 0.1 \
  --pvalue_threshold 0.05 \
  --sign True \
  --subset_methods True \
  --output "../../data/figure_s7/output/seqtime"
