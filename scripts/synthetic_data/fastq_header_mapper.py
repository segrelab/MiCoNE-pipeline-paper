#!/usr/bin/env python3

from collections import defaultdict
import csv
import pathlib


def main(fastq_files, output_folder):
    num_size = 6
    count = 0
    map_dict = defaultdict(list)
    for fastq_file in fastq_files:
        output_file = output_folder / fastq_file.name
        with open(fastq_file, 'r') as in_fid:
            with open(output_file, 'w') as out_fid:
                for line in in_fid:
                    if line.startswith('@'):
                        tax = line[1:].split('-', 1)[0]
                        id_ = str(count).zfill(num_size)
                        map_dict[tax].append(id_)
                        count += 1
                        out_fid.write(f"@{id_}\n")
                    else:
                        out_fid.write(line)
    csv_file = output_folder / "map_file.csv"
    with open(csv_file, 'w') as fid:
        csv_writer = csv.writer(fid, delimiter=',')
        for k, v in map_dict.items():
            csv_writer.writerow([k, *v])


if __name__ == "__main__":
    FILES = pathlib.Path("../seqs/art/original").glob("*.fq")
    OUT_FOL = pathlib.Path("../seqs/art")
    main(FILES, OUT_FOL)
