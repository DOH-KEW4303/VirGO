nextflow.enable.dsl=2
include { VIRGO } from './workflows/virgo'

workflow {
  VIRGO()
}