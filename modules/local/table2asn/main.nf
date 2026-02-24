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