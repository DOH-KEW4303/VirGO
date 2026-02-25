include { SEQSENDER } from '../modules/local/seqsender/main'
include { VADR } from '../modules/local/vadr/main'
include { TABLE2ASN } from '../modules/local/table2asn/main'

workflow VIRGO {

  if( !params.submission_name || !params.config || !params.metadata || !params.fasta ) {
    error "Missing required parameters"
  }

  models_ch = Channel.value( file(params.vadr_models) )

  seq = SEQSENDER(
    file(params.config),
    file(params.metadata),
    file(params.fasta)
  )

  vadr = VADR(seq.seq_fsa, models_ch)

  TABLE2ASN(seq.seq_fsa, seq.src, seq.auth, vadr.vadr_dir)
}