#!/bin/bash

### NoRTA

CORR=("sparcc" "propr" "spearman" "pearson")
for ((i = 0; i < ${#CORR[@]}; i++)); do
  python data_extraction.py \
    --folder "/home/dileep/Documents/Work/MIND/synthetic_interactions/pipeline/norta/outputs" \
    --workflow network_inference \
    --module network \
    --process make_network_with_pvalue \
    --previous_process "----${CORR[$i]}" \
    "../data/figure5/input/norta/${CORR[$i]}"
done

DIR=("spieceasi" "flashweave" "mldm" "cozine" "harmonies" "spring")
for ((i = 0; i < ${#DIR[@]}; i++)); do
  python data_extraction.py \
    --folder "/home/dileep/Documents/Work/MIND/synthetic_interactions/pipeline/norta/outputs" \
    --workflow network_inference \
    --module network \
    --process make_network_without_pvalue \
    --previous_process "----${DIR[$i]}" \
    "../data/figure5/input/norta/${DIR[$i]}"
done

### Seqtime
CORR=("sparcc" "propr" "spearman" "pearson")
for ((i = 0; i < ${#CORR[@]}; i++)); do
  python data_extraction.py \
    --folder "/home/dileep/Documents/Work/MIND/synthetic_interactions/pipeline/seqtime/outputs" \
    --workflow network_inference \
    --module network \
    --process make_network_with_pvalue \
    --previous_process "----${CORR[$i]}" \
    "../data/figure5/input/seqtime/${CORR[$i]}"
done

DIR=("spieceasi" "flashweave" "mldm" "cozine" "harmonies" "spring")
for ((i = 0; i < ${#DIR[@]}; i++)); do
  python data_extraction.py \
    --folder "/home/dileep/Documents/Work/MIND/synthetic_interactions/pipeline/seqtime/outputs" \
    --workflow network_inference \
    --module network \
    --process make_network_without_pvalue \
    --previous_process "----${DIR[$i]}" \
    "../data/figure5/input/seqtime/${DIR[$i]}"
done
