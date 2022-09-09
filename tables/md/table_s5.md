|   Task    |        Tool        |     Parameter     |                           Value                            |
| :-------: | :----------------: | :---------------: | :--------------------------------------------------------: |
| Transform |        Fork        |       axis        |                          "sample"                          |
| Transform |        Fork        |      column       |                             ""                             |
| Transform | Normalize & Filter |       axis        |                           "None"                           |
| Transform | Normalize & Filter |    count_thres    |                            500                             |
| Transform | Normalize & Filter | prevalence_thres  |                            0.05                            |
| Transform | Normalize & Filter |   obssum_thres    |                            100                             |
| Transform | Normalize & Filter |   rm_sparse_obs   |                       [true, false]                        |
| Transform | Normalize & Filter | rm_sparse_samples |                            true                            |
| Transform | Normalize & Filter |  abundance_thres  |                            0.01                            |
| Transform |       Group        |    tax_levels     | ['Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species'] |