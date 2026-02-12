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

process SEQSENDER {
  tag "${params.submission_name}"
  container 'ghcr.io/cdcgov/seqsender:v1.3.9'
  publishDir "${params.outdir}/10_seqsender", mode: 'copy'

  input:
    path config_file
    path metadata_file
    path fasta_file

  output:
    path "${params.submission_name}/submission_files/GENBANK/sequence.fsa", emit: seq_fsa
    path "${params.submission_name}/submission_files/GENBANK/source.src",  emit: src
    path "${params.submission_name}/submission_files/GENBANK/authorset.sbt", emit: auth

  script:
  """
  bash /seqsender/seqsender-kickoff submit \
    -n -b \
    --organism ${params.organism} \
    --submission_name ${params.submission_name} \
    --submission_dir \$PWD \
    --config_file \$(realpath ${config_file}) \
    --metadata_file \$(realpath ${metadata_file}) \
    --fasta_file \$(realpath ${fasta_file})
  """
}

process VADR {
  tag "${params.submission_name}"
  container params.vadr_image
  publishDir "${params.outdir}/20_vadr", mode: 'copy'

  input:
    path seq_fsa
    path vadr_models_dir

  output:
    path "vadr_out", emit: vadr_dir

  script:
  """
  v-annotate.pl \
    --indefclass ${params.vadr_indefclass} \
    --mkey ${params.vadr_mkey} \
    --mdir ${vadr_models_dir} \
    ${seq_fsa} \
    vadr_out
  """
}

process TABLE2ASN {
  tag "${params.submission_name}"
  publishDir "${params.outdir}/final", mode: 'copy'

  input:
    path seq_fsa
    path src
    path auth
    path vadr_dir

  output:
    path "${params.submission_name}.sqn"
    path "${params.submission_name}.val"

  script:
  """
  set -euo pipefail

  PASS_TBL=\$(ls ${vadr_dir}/*.vadr.pass.tbl | head -n 1)


  table2asn \
    -t ${auth} \
    -i ${seq_fsa} \
    -f \$PASS_TBL \
    -src-file ${src} \
    -o ${params.submission_name}.sqn \
    -V vb \
    -a s

  # keep Nextflow happy even if .val isn't produced for some reason
  [ -f ${params.submission_name}.val ] || touch ${params.submission_name}.val
  """
}

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