+------------+---------+-------------------+----------------+----------+
| Step       | Task    | Tool              | Parameter      | Value    |
+============+=========+===================+================+==========+
| Sequence   | Demulti | demultiplexin     | barcode_column | barcode- |
| Processing | plexing | g_illumina_single |                | sequence |
+------------+---------+-------------------+----------------+----------+
| Sequence   | Demulti | demultiplexin     | rev            | false    |
| Processing | plexing | g_illumina_single | _comp_barcodes |          |
+------------+---------+-------------------+----------------+----------+
| Sequence   | Demulti | demultiplexin     | rev_comp_ma    | false    |
| Processing | plexing | g_illumina_single | pping_barcodes |          |
+------------+---------+-------------------+----------------+----------+
| Sequence   | Demulti | demultiplexin     | barcode_column | barcode- |
| Processing | plexing | g_illumina_paired |                | sequence |
+------------+---------+-------------------+----------------+----------+
| Sequence   | Demulti | demultiplexin     | rev            | false    |
| Processing | plexing | g_illumina_paired | _comp_barcodes |          |
+------------+---------+-------------------+----------------+----------+
| Sequence   | Demulti | demultiplexin     | rev_comp_ma    | false    |
| Processing | plexing | g_illumina_paired | pping_barcodes |          |
+------------+---------+-------------------+----------------+----------+
| Sequence   | T       | export_vis        | seq_samplesize | 10000    |
| Processing | rimming | ualization_single |                |          |
+------------+---------+-------------------+----------------+----------+
| Sequence   | T       | export_vis        | seq_samplesize | 10000    |
| Processing | rimming | ualization_paired |                |          |
+------------+---------+-------------------+----------------+----------+
| Sequence   | T       | trimming_single   | ncpus          | 1        |
| Processing | rimming |                   |                |          |
+------------+---------+-------------------+----------------+----------+
| Sequence   | T       | trimming_single   | max_ee         | 2        |
| Processing | rimming |                   |                |          |
+------------+---------+-------------------+----------------+----------+
| Sequence   | T       | trimming_single   | trunc_q        | 2        |
| Processing | rimming |                   |                |          |
+------------+---------+-------------------+----------------+----------+
| Sequence   | T       | trimming_paired   | ncpus          | 1        |
| Processing | rimming |                   |                |          |
+------------+---------+-------------------+----------------+----------+
| Sequence   | T       | trimming_paired   | max_ee         | 2        |
| Processing | rimming |                   |                |          |
+------------+---------+-------------------+----------------+----------+
| Sequence   | T       | trimming_paired   | trunc_q        | 2        |
| Processing | rimming |                   |                |          |
+------------+---------+-------------------+----------------+----------+
