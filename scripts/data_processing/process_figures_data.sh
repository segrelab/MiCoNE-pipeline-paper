#!/bin/bash -l

#$ -l h_rt=10:00:00
#$ -N micone_data_processing
#$ -hold_jid micone_data_extraction
#$ -P visant
#$ -o processing_outputs.txt
#$ -e processing_errors.txt
#$ -m e
#$ -pe omp 8

# TODO: Change before running
PLATFORM="scc"
DATASET="FMT"

if [ $PLATFORM == "scc" ]; then
  module load miniconda
  conda activate micone-figures-py
fi

# Figure 2
echo "Processing Figure 2"
cd ../figure2/
rm -f *.pkl
mkdir -pv "../../data/figure2/output/$DATASET"
# NOTE: This requires 8 cpu cores
python figure2_data.py \
  --files "../../data/figure2/input/$DATASET/**/*.json" \
  --level "Genus" \
  --interaction_threshold 0.1 \
  --pvalue_threshold 0.05 \
  --ncpus 8 \
  --output "../../data/figure2/output/$DATASET"

# Figure 4
echo "Processing Figure 4"
cd ../figure4/
mkdir -pv ../../data/figure4/output/$DATASET
python figure4ab_data.py \
  --files "../../data/figure4/input/$DATASET/**/otu_table_wtax.biom" \
  --notus 100 \
  --output "../../data/figure4/output/$DATASET"

# Figure 5
echo "Processing Figure 5"
mkdir -pv ../../data/figure5/output/$DATASET
cd ../figure5/
python -W ignore figure5_data.py \
  --files ../../data/figure5/input/$DATASET/**/*_network.json \
  --color_key_level "Family" \
  --multigraph True \
  --output ../../data/figure5/output/$DATASET

# Figure 6
echo "Processing Figure 6"
cd ../figure6/
rm -f *.pkl
mkdir -pv "../../data/figure6/output/norta"
python -W ignore figure6_data.py \
  --files "../../data/figure6/input/norta/**/*.json" \
  --interaction_threshold 0.1 \
  --pvalue_threshold 0.05 \
  --sign True \
  --output "../../data/figure6/output/norta"

# Figure 7
echo "Processing Figure 7"
cd ../figure7/
mkdir -pv "../../data/figure7/output/$DATASET"
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

# Figure 3
echo "Processing Figure 3"
cd ../figure3/
mkdir -pv ../../data/figure3/intermediate/$DATASET
mkdir -pv ../../data/figure3/output/$DATASET
if [ $PLATFORM == "local" ]; then
  export PATH=$HOME/anaconda3/bin:$PATH
  source activate micone-qiime2
elif [ $PLATFORM == "scc" ]; then
  conda activate micone-qiime2
else
  echo "Unknown platform"
fi
# Make trees
# NOTE: This requires 8 cpu cores
python make_trees.py \
  --base_dir ../../data/figure3/input/$DATASET \
  --output_dir ../../data/figure3/intermediate/$DATASET
# Unweighted unifrac
python figure3_data.py \
  --trees ../../data/figure3/intermediate/$DATASET/trees/**/*.nwk \
  --otus ../../data/figure3/input/$DATASET/**/*_filtered.biom \
  --weighted False \
  --threshold 10 \
  --output ../../data/figure3/output/$DATASET
# Weighted unifrac
python figure3_data.py \
  --trees ../../data/figure3/intermediate/$DATASET/trees/**/*.nwk \
  --otus ../../data/figure3/input/$DATASET/**/*_filtered.biom \
  --weighted True \
  --threshold 10 \
  --output ../../data/figure3/output/$DATASET
