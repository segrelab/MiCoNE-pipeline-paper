#!/bin/bash -l

#$ -l h_rt=1:00:00
#$ -N micone_figure_generation
#$ -hold_jid micone_data_extraction,micone_data_processing
#$ -P visant
#$ -o figure_outputs.txt
#$ -e figure_errors.txt
#$ -m e
#$ -pe omp 4

# TODO: Change this before running
PLATFORM="scc"
DATASET="FMT"
OUTPUT_DIR="../../figures/FMT/"
mkdir -pv $OUTPUT_DIR

if [ $PLATFORM == "scc" ]; then
  module load miniconda
  conda activate micone-figures
fi

# Figure 2
echo "Generating Figure 2"
cd ../figure2/
Rscript figure2_plot.R "../../data/figure2/output/$DATASET/" "$OUTPUT_DIR"

# Figure 3
echo "Generating Figure 3"
cd ../figure3/
Rscript figure3_plot.R \
  "../../data/figure3/output/$DATASET/" \
  "../../data/figure3/output/" \
  "$OUTPUT_DIR"

# Figure 4
echo "Generating Figure 4"
cd ../figure4/
Rscript figure4_plot.R \
  "../../data/figure4/output/$DATASET/" \
  "../../data/figure4/output/" \
  "$OUTPUT_DIR"

# Figure 5
echo "Generating Figure 5"
cd ../figure5/
Rscript figure5_plot.R "../../data/figure5/output/$DATASET/" "$OUTPUT_DIR"

# Figure 6
echo "Generating Figure 6"
cd ../figure6/
Rscript figure6_plot.R "../../data/figure6/output/$DATASET/" "fmt-control" "fmt-autism" "$OUTPUT_DIR"

# Figure 7
echo "Generating Figure 7"
cd ../figure7/
Rscript figure7_plot.R "../../data/figure7/output/norta/" "$OUTPUT_DIR"
