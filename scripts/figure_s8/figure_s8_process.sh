#!/usr/bin/env bash

cd ../figure_s6/
rm -f *.pkl
mkdir -pv "../../data/figure_s8/output/norta"
python -W ignore figure_s6_data.py \
  --files "../../data/figure5/input/norta/**/*.json" \
  --interaction_threshold 0.1 \
  --pvalue_threshold 0.05 \
  --sign True \
  --subset_methods False \
  --output "../../data/figure_s8/output/norta"
