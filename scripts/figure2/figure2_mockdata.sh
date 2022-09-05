#!/usr/bin/env bash

DATASET=("mock4" "mock12" "mock16")
for i in "${DATASET[@]}"; do
  python -W ignore figure2_data.py \
    --trees "../../data/figure2/intermediate/$i/trees/**/*.nwk" \
    --otus "../../data/figure2/input/$i/**/*.biom" \
    --weighted False \
    --asv False \
    --threshold 10 \
    --output "../../data/figure2/output/$i"

  python -W ignore figure2_data.py \
    --trees "../../data/figure2/intermediate/$i/trees/**/*.nwk" \
    --otus "../../data/figure2/input/$i/**/*.biom" \
    --weighted True \
    --asv False \
    --threshold 10 \
    --output "../../data/figure2/output/$i"
done
