process SYNC_BIOSAMPLE_STATUS {
  tag "${params.submission_name}"
  container 'ghcr.io/cdcgov/seqsender:v1.3.91'

  input:
    // this is the folder named exactly ${params.submission_name}
    path submission_dir
    path config_file

  output:
    // pass-through + “post-sync” versions
    
    path submission_dir, emit: submission_dir
    path "${submission_dir}/submission_files/submission_status_report.csv", emit: status_csv
    path "biosample.sync.done", emit: done

  script:
  """
  set -euo pipefail

  SUBDIR="\$(realpath ${submission_dir})"
  BASEDIR="\$(dirname "\$SUBDIR")"
  REPORT="\$SUBDIR/submission_files/submission_status_report.csv"
  
  LOG_FILE="\$BASEDIR/submission_log.csv"
  CONFIG_PATH="\$(realpath ${config_file})"

  python3 - <<PY
  import csv

  log_file = r"\${LOG_FILE}"
  config_path = r"\${CONFIG_PATH}"
  rows = []

  with open(log_file, newline="") as fh:
      reader = csv.DictReader(fh)
      fieldnames = reader.fieldnames
      for row in reader:
          if row["Submission_Name"] == "${params.submission_name}":
              row["Config_File"] = config_path
          rows.append(row)

  with open(log_file, "w", newline="") as fh:
      writer = csv.DictWriter(fh, fieldnames=fieldnames)
      writer.writeheader()
      writer.writerows(rows)
  PY

  INTERVAL=${params.poll_interval ?: 300}
  MAX_SECONDS=\$(( (${params.poll_max_minutes ?: 240}) * 60 ))
  MAX_FAILS=${params.poll_max_failures ?: 3}
  REQUIRE_ALL=${params.poll_require_all_biosample_accessions ?: 'true'}

  elapsed=0
  fail_count=0

  echo "SYNC_BIOSAMPLE_STATUS: polling for BioSample accessions in: \$REPORT"
  echo "submission_name = ${params.submission_name}"
  echo "organism        = ${params.organism}"
  echo "submission_base = \$BASEDIR"
  echo "submission_dir  = \$SUBDIR"
  echo "interval (sec)  = \$INTERVAL"
  echo "max (sec)       = \$MAX_SECONDS"
  echo "require_all     = \$REQUIRE_ALL"

  # sanity check: shared log must be in BASEDIR
  test -f "\$BASEDIR/submission_log.csv" || { 
    echo "ERROR: missing \$BASEDIR/submission_log.csv"; 
    ls -lah "\$BASEDIR"; 
    exit 1; 
  }

  while true; do
    set +e
    bash /seqsender/seqsender-kickoff submission_status \
      --submission_name ${params.submission_name} \
      --submission_dir "\$BASEDIR"
    status_rc=\$?
    set -e

    echo "submission_status exit code: \$status_rc"

    XML_REPORT="\$SUBDIR/submission_files/BIOSAMPLE/report.xml"

    if [[ -f "\$XML_REPORT" ]]; then
      echo "Found XML report: \$XML_REPORT"

      if grep -qi "processed-error" "\$XML_REPORT"; then
        echo "ERROR: BioSample submission reached processed-error" >&2
        cat "\$XML_REPORT" >&2
        exit 1
      fi
    fi

    if [[ -f "\$REPORT" ]]; then
      echo "Found report: \$REPORT"
      head -20 "\$REPORT" || true

      if [[ "\$REQUIRE_ALL" == "true" ]]; then
        awk -F',' 'NR>1 {n++; if(\$3=="") missing++} END{exit(n>0 && missing==0 ? 0 : 1)}' "\$REPORT" && break || true
      else
        awk -F',' 'NR>1 && \$3!="" {found=1} END{exit(found?0:1)}' "\$REPORT" && break || true
      fi
    fi

    if [[ \$status_rc -ne 0 ]]; then
      fail_count=\$(( \$fail_count + 1 ))
      echo "submission_status failed (\$fail_count consecutive times)"
    else
      fail_count=0
    fi


    if (( \$elapsed >= MAX_SECONDS )); then
      echo "ERROR: timed out after ${params.poll_max_minutes ?: 240} minutes waiting for BioSample accessions." >&2
      echo "Expected status report at: \$REPORT" >&2
      exit 1
    fi

    if (( \$fail_count >= MAX_FAILS )); then
    if [[ ! -f "\$SUBDIR/submission_files/BIOSAMPLE/report.xml" ]]; then
      echo "ERROR: submission_status failed \$MAX_FAILS times and no report.xml found." >&2
      exit 1
    else
      echo "WARNING: submission_status failing, but report.xml exists — continuing to poll"
      fail_count=0
    fi
  fi

    sleep "\$INTERVAL"
    elapsed=\$(( elapsed + INTERVAL ))
  done

  echo "SYNC_BIOSAMPLE_STATUS: BioSample accessions detected."
  touch biosample.sync.done
  """
}