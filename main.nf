nextflow.enable.dsl=2

params.submission_name = null
params.config          = null
params.metadata        = null
params.fasta           = null
params.outdir          = 'results'

// seqsender knob
params.organism        = 'OTHER'

// VADR knobs (MeV defaults)
params.vadr_image      = 'staphb/vadr:1.6.4-mev'
params.vadr_mkey       = 'mev'
params.vadr_models     = '/data/vadr-1.7/vadr-models-mev/mev'
params.vadr_indefclass = '0.01'

include { SEQSENDER } from './modules/local/seqsender/main'
include {VADR} from './modules/local/vadr/main'
include {TABLE2ASN} from './modules/local/table2asn/main'


workflow {
  if( !params.submission_name || !params.config || !params.metadata || !params.fasta ) {
    error """
    Missing required parameters.

    Required:
      --submission_name
      --config
      --metadata
      --fasta
    """
  }

  // Ensure VADR models dir is staged/mounted into container
  models_ch = Channel.value( file(params.vadr_models) )

  seq = SEQSENDER(
    file(params.config),
    file(params.metadata),
    file(params.fasta)
  )

  vadr = VADR(seq.seq_fsa, models_ch)

  TABLE2ASN(seq.seq_fsa, seq.src, seq.auth, vadr.vadr_dir)
}