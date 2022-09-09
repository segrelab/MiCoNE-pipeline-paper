|         Step        |      Task      |              Tool              |         Parameter         |       Value      |
|:-------------------:|:--------------:|:------------------------------:|:-------------------------:|:----------------:|
| Sequence Processing | Demultiplexing | demultiplexing_illumina_single |       barcode_column      | barcode-sequence |
| Sequence Processing | Demultiplexing | demultiplexing_illumina_single |     rev_comp_barcodes     |       false      |
| Sequence Processing | Demultiplexing | demultiplexing_illumina_single | rev_comp_mapping_barcodes |       false      |
| Sequence Processing | Demultiplexing | demultiplexing_illumina_paired |       barcode_column      | barcode-sequence |
| Sequence Processing | Demultiplexing | demultiplexing_illumina_paired |     rev_comp_barcodes     |       false      |
| Sequence Processing | Demultiplexing | demultiplexing_illumina_paired | rev_comp_mapping_barcodes |       false      |
| Sequence Processing |    Trimming    |   export_visualization_single  |       seq_samplesize      |       10000      |
| Sequence Processing |    Trimming    |   export_visualization_paired  |       seq_samplesize      |       10000      |
| Sequence Processing |    Trimming    |         trimming_single        |           ncpus           |         1        |
| Sequence Processing |    Trimming    |         trimming_single        |           max_ee          |         2        |
| Sequence Processing |    Trimming    |         trimming_single        |          trunc_q          |         2        |
| Sequence Processing |    Trimming    |         trimming_paired        |           ncpus           |         1        |
| Sequence Processing |    Trimming    |         trimming_paired        |           max_ee          |         2        |
| Sequence Processing |    Trimming    |         trimming_paired        |          trunc_q          |         2        |