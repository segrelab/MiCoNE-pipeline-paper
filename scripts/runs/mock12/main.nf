// -*- mode:groovy -*-
// vim:ft=groovy

nextflow.enable.dsl=2

// Include workflows
include { denoise_cluster_workflow } from './nf_micone/modules/denoise_cluster/denoise_cluster_workflow.nf'
include { tax_assignment_workflow } from './nf_micone/modules/tax_assignment/tax_assignment_workflow.nf'
include { otu_processing_workflow } from './nf_micone/modules/otu_processing/otu_processing_workflow.nf'
include { network_inference_workflow } from './nf_micone/modules/network_inference/network_inference_workflow.nf'

// Include data ingestion functions
include { dc_data_ingestion } from './nf_micone/modules/utils/dc_data_ingestion.nf'

// Channels for samplesheets
Channel
    .fromPath(params.input)
    .set { input_channel }

workflow {
    input_channel \
        | dc_data_ingestion \
        | denoise_cluster_workflow \
        | tax_assignment_workflow \
        | otu_processing_workflow
}
