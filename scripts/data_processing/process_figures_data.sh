#!/usr/bin/env bash

PLATFORM="local" # change to scc on the SCC
DATASET="moving_pictures"

if [ $PLATFORM == "scc" ]; then
  module load miniconda
  conda activate micone-figures-py
fi

# Figure 2
echo "Processing Figure 2"
cd ../figure2/
# NOTE: This requires 4 cpu cores
python figure2_data.py \
  --files "../../data/figure2/input/$DATASET/**/*.json" \
  --level "Genus" \
  --interaction_threshold 0.1 \
  --pvalue_threshold 0.05 \
  --ncpus 4 \
  --output "../../data/figure2/output/$DATASET"

# Figure 4
echo "Processing Figure 4"
cd ../figure4/
python figure4ab_data.py \
  --files ../../data/figure4/input/$DATASET/**/otu_table_wtax.biom \
  --notus 100 \
  --output ../../data/figure4/output/$DATASET

# Figure 5
echo "Processing Figure 5"
cd ../figure5/
python -W ignore figure5_data.py \
  --files ../../data/figure5/input/$DATASET/**/*_network.json \
  --color_key_level "Family" \
  --multigraph True \
  --output ../../data/figure5/output/$DATASET

# Figure 6
echo "Processing Figure 6"
cd ../figure6/
python -W ignore figure6_data.py \
  --folder "../../data/figure6/input/$DATASET" \
  --color_key_level "Family" \
  --multigraph "False" \
  --dc "closed_reference(gg_97)" \
  --cc "uchime" \
  --ta "blast(ncbi)" \
  --op "normalize_filter(off)" \
  --ni "sparcc" \
  --output "../../data/figure6/output/$DATASET"

# Figure 3
echo "Processing Figure 3"
cd ../figure3/
if [ $PLATFORM == "local" ]; then
  export PATH=$HOME/anaconda3/bin:$PATH
  source activate micone-qiime2
elif [ $PLATFORM == "scc" ]; then
  conda activate micone-qiime2
else
  echo "Unknown platform"
fi
# Make trees
# NOTE: This requires 4 cpu cores
python make_trees.py \
  --base_dir ../../data/figure3/input/$DATASET \
  --output_dir ../../data/figure3/intermediate/$DATASET
# Unweighted unifrac
python figure3_data.py \
  --trees ../../data/figure3/intermediate/$DATASET/trees/**/*.nwk \
  --otus ../../data/figure3/input/$DATASET/**/*.biom \
  --weighted False \
  --threshold 3 \
  --output ../../data/figure3/output/$DATASET
# Weighted unifrac
python figure3_data.py \
  --trees ../../data/figure3/intermediate/$DATASET/trees/**/*.nwk \
  --otus ../../data/figure3/input/$DATASET/**/*.biom \
  --weighted True \
  --threshold 3 \
  --output ../../data/figure3/output/$DATASET
