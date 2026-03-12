include { SEQSENDER } from '../modules/local/seqsender/main.nf'
include { SYNC_BIOSAMPLE_STATUS } from '../modules/local/sync_biosample_status/main.nf'
include { ADD_SAMN_SRC } from '../modules/local/ADD_SAMN_SRC/main.nf'
include { VADR } from '../modules/local/vadr/main.nf'
include { TABLE2ASN } from '../modules/local/table2asn/main.nf'

workflow VIRGO {

  if( !params.submission_name || !params.config || !params.metadata || !params.fasta || !params.vadr_models) {
    error "Missing required parameters"
  }

  models_ch = Channel.value( file(params.vadr_models, checkIfExists: true) )
  config_ch   = Channel.fromPath(params.config,   checkIfExists: true)
  metadata_ch = Channel.fromPath(params.metadata, checkIfExists: true)
  fasta_ch    = Channel.fromPath(params.fasta,    checkIfExists: true)

  seq  = SEQSENDER(config_ch, metadata_ch, fasta_ch)
  vadr = VADR(seq.seq_fsa, models_ch)

  do_sync = (params.submit_biosample && !params.dry_run)

  if (do_sync) {
    synced  = SYNC_BIOSAMPLE_STATUS(seq.submission_dir)
    addsamn = ADD_SAMN_SRC(seq.submission_dir, seq.src, synced.done)

    TABLE2ASN(seq.seq_fsa, addsamn.src, seq.auth, vadr.vadr_dir)
} else {
    TABLE2ASN(seq.seq_fsa, seq.src, seq.auth, vadr.vadr_dir)
}

}



