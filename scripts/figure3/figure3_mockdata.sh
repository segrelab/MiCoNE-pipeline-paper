#!/usr/bin/env bash

DATASET=("mock4" "mock12" "mock16")
for i in "${DATASET[@]}"; do
  python figure3_data.py \
    --trees "../../data/figure3/intermediate/$i/trees/**/*.nwk" \
    --otus "../../data/figure3/input/$i/**/*.biom" \
    --weighted False \
    --asv False \
    --threshold 10 \
    --output "../../data/figure3/output/$i"

  python figure3_data.py \
    --trees "../../data/figure3/intermediate/$i/trees/**/*.nwk" \
    --otus "../../data/figure3/input/$i/**/*.biom" \
    --weighted True \
    --asv False \
    --threshold 10 \
    --output "../../data/figure3/output/$i"
done
