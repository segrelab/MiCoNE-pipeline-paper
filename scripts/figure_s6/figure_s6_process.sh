#!/usr/bin/env bash

cd ../figure_s6/
rm -f *.pkl
mkdir -pv "../../data/figure_s6/output/seqtime"
python -W ignore figure_s6_data.py \
  --files "../../data/figure5/input/seqtime/**/*.json" \
  --interaction_threshold 0.1 \
  --pvalue_threshold 0.05 \
  --sign True \
  --subset_methods True \
  --output "../../data/figure_s6/output/seqtime"
