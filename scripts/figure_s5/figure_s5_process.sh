#!/usr/bin/env bash

DATASET="FMT"

cd ../figure4/
mkdir -pv ../../data/figure_s5/output/$DATASET
python figure4ab_data.py \
  --files "../../data/figure4/input/$DATASET/**/otu_table_wtax.biom" \
  --notus -1 \
  --output "../../data/figure_s5/output/$DATASET"
