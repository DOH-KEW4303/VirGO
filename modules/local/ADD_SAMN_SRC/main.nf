process ADD_SAMN_SRC {
  tag "${params.submission_name}"
  container params.add_samn_image ?: 'python:3.11'

  input:
    path submission_dir
    path src_in
    path sync_done

  output:
    path "source.src", emit: src

  script:
  """
  set -euo pipefail

  pip install --quiet pandas
  STATUS_CSV="${submission_dir}/submission_files/submission_status_report.csv" \
  SRC_IN="${src_in}" \
  REQUIRE_ALL="${params.require_all_samn ?: true}" \
  python - <<'PY'
  import os
  import pandas as pd

  status_path = os.environ["STATUS_CSV"]
  src_path    = os.environ["SRC_IN"]

  require_all = str(os.environ.get("REQUIRE_ALL", "true")).lower() in ("1","true","yes","y")

  if not os.path.exists(status_path):
    raise SystemExit(f"ERROR: submission_status_report.csv not found at: {status_path}")

  status = pd.read_csv(status_path, dtype=str).fillna("")
  src    = pd.read_csv(src_path, sep="\\t", dtype=str).fillna("")


  # Validate expected columns
  for col in ["gb-sample_name", "biosample_accession"]:
    if col not in status.columns:
      raise SystemExit(f"ERROR: status file missing column: {col}")

  if "Sequence_ID" not in src.columns:
    raise SystemExit("ERROR: source.src missing required column: Sequence_ID")

  # Build gb-sample_name -> SAMN map (keep first per gb-sample_name)
  m = (
    status.loc[status["biosample_accession"].str.strip().ne(""), ["gb-sample_name", "biosample_accession"]]
          .drop_duplicates(subset=["gb-sample_name"])
          .set_index("gb-sample_name")["biosample_accession"]
  )

  # Add/overwrite BioSample
  src["BioSample"] = src["Sequence_ID"].map(m).fillna("")

  if require_all:
    missing = src.loc[src["BioSample"].str.strip().eq(""), "Sequence_ID"].tolist()
    if missing:
      preview = ", ".join(missing[:10])
      raise SystemExit(
        f"ERROR: Missing BioSample accessions for {len(missing)} Sequence_IDs. "
        f"Examples: {preview}"
      )

  src.to_csv("source.src", sep="\\t", index=False)
  print(f"ADD_SAMN_SRC: wrote updated source.src with BioSample column. require_all={require_all}")
  PY
  """
}