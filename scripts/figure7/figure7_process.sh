#!/usr/bin/env bash

DATASET=FMT
python -W ignore figure7_data.py \
  --folder "../../data/figure7/input/$DATASET" \
  --color_key_level "Family" \
  --multigraph "False" \
  --dc "closed_reference(gg_97)" \
  --cc "uchime" \
  --ta "blast(ncbi)" \
  --op "normalize_filter(off)" \
  --ni "sparcc" \
  --dataset "fmt-control" \
  --output "../../data/figure7/output/$DATASET"
python -W ignore figure7_data.py \
  --folder "../../data/figure7/input/$DATASET" \
  --color_key_level "Family" \
  --multigraph "False" \
  --dc "closed_reference(gg_97)" \
  --cc "uchime" \
  --ta "blast(ncbi)" \
  --op "normalize_filter(off)" \
  --ni "sparcc" \
  --dataset "fmt-autism" \
  --output "../../data/figure7/output/$DATASET"
