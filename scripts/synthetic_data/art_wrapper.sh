#!/usr/bin/env bash

for i in ../outputs/seq_pools/*.fasta; do
	fname=$(basename -s .fasta "$i")
	art_illumina -ss HS25 -amp -na -i "$i" -l 150 -f 1 -o "../outputs/reads/$fname"
done
