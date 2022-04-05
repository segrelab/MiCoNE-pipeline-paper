#!/bin/bash -l

cd data_extraction
rm *.txt
qsub extract_figures_data.sh

cd data_processing
rm *.txt
qsub process_figures_data.sh

cd figure_generation
rm *.txt
qsub generate_figures.sh