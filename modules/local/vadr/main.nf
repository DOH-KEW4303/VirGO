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