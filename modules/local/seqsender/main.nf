process SEQSENDER {
  tag "${params.submission_name}"
  container 'ghcr.io/cdcgov/seqsender:v1.3.9'
  publishDir "${params.outdir}/10_seqsender", mode: 'copy'

  input:
    path config_file
    path metadata_file
    path fasta_file

  
  output:
  // full submission outputs BIOSAMPLE+GENBANK
  path "${params.submission_name}", emit: submission_dir

  // files used downstream for VADR+table2asn
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
    --fasta_file \$(realpath ${fasta_file}) \
    --test
  """
}