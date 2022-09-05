#!/bin/bash -l

#$ -l h_rt=14:00:00
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

# Figure 6
echo "Processing Figure 6"
cd ../figure6/
rm -f *.pkl
mkdir -pv "../../data/figure6/output/$DATASET"
# NOTE: This requires 8 cpu cores
python figure6_data.py \
  --files "../../data/figure6/input/$DATASET/**/*.json" \
  --level "Genus" \
  --interaction_threshold 0.1 \
  --pvalue_threshold 0.05 \
  --ncpus 8 \
  --output "../../data/figure6/output/$DATASET"

# Figure 3
echo "Processing Figure 3"
cd ../figure3/
mkdir -pv ../../data/figure3/output/$DATASET
python figure3ab_data.py \
  --files "../../data/figure3/input/$DATASET/**/otu_table_wtax.biom" \
  --notus 100 \
  --output "../../data/figure3/output/$DATASET"

# Figure 4
echo "Processing Figure 4"
mkdir -pv ../../data/figure4/output/$DATASET
cd ../figure4/
python -W ignore figure4_data.py \
  --files ../../data/figure4/input/$DATASET/**/*_network.json \
  --color_key_level "Family" \
  --multigraph True \
  --output ../../data/figure4/output/$DATASET

# Figure 5
echo "Processing Figure 5"
cd ../figure5/
rm -f *.pkl
mkdir -pv "../../data/figure5/output/norta"
python -W ignore figure5_data.py \
  --files "../../data/figure5/input/norta/**/*.json" \
  --interaction_threshold 0.1 \
  --pvalue_threshold 0.05 \
  --sign True \
  --output "../../data/figure5/output/norta"

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

# Figure 2
echo "Processing Figure 2"
cd ../figure2/
mkdir -pv ../../data/figure2/intermediate/$DATASET
mkdir -pv ../../data/figure2/output/$DATASET
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
  --base_dir ../../data/figure2/input/$DATASET \
  --output_dir ../../data/figure2/intermediate/$DATASET
# Unweighted unifrac
python -W ignore figure2_data.py \
  --trees ../../data/figure2/intermediate/$DATASET/trees/**/*.nwk \
  --otus ../../data/figure2/input/$DATASET/**/*_filtered.biom \
  --weighted False \
  --threshold 10 \
  --output ../../data/figure2/output/$DATASET
# Weighted unifrac
python -W ignore figure2_data.py \
  --trees ../../data/figure2/intermediate/$DATASET/trees/**/*.nwk \
  --otus ../../data/figure2/input/$DATASET/**/*_filtered.biom \
  --weighted True \
  --threshold 10 \
  --output ../../data/figure2/output/$DATASET

#### Supplementary figures
