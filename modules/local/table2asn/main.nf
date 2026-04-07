process TABLE2ASN {
  tag "${params.submission_name}"
  container params.table2asn_image
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

  PASS_TBL=\$(ls vadr_out/*.vadr.pass.tbl 2>/dev/null | head -n 1 || true)
  FAIL_TBL=\$(ls vadr_out/*.vadr.fail.tbl 2>/dev/null | head -n 1 || true)

if [[ -n "\${PASS_TBL}" && -s "\${PASS_TBL}" ]]; then
    echo "Using VADR pass table: \${PASS_TBL}"
    TBL="\${PASS_TBL}"
elif [[ -n "\${FAIL_TBL}" && -s "\${FAIL_TBL}" ]]; then
    echo "PASS table empty or missing; using FAIL table instead: \${FAIL_TBL}"
    TBL="\${FAIL_TBL}"
else
    echo "ERROR: No non-empty VADR annotation table found."
    exit 1
fi

  table2asn \
    -t ${auth} \
    -i ${seq_fsa} \
    -f "\${TBL}" \
    -src-file ${src} \
    -o ${params.submission_name}.sqn \
    -V vb \
    -a s

  # keep Nextflow happy even if .val isn't produced for some reason
  [ -f ${params.submission_name}.val ] || touch ${params.submission_name}.val
  """
}