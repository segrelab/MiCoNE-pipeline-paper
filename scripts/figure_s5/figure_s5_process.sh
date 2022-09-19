#!/usr/bin/env bash

mkdir -pv "../../data/figure_s5/output/norta"
python -W ignore figure_s5_data.py \
  --files "../../data/figure5/input/norta/**/*.json" \
  --interaction_threshold 0.1 \
  --pvalue_threshold 0.05 \
  --sign True \
  --output "../../data/figure_s5/output/norta"
