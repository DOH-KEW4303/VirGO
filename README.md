
<img width="546" height="264" alt="ChatGPT Image Feb 11, 2026, 03_30_32 PM" src="https://github.com/user-attachments/assets/7b9ff496-d49d-44c7-931a-f0aecbb67d58" />


# VirGO: Viral Genome Submission File Orchestration
Created for non-flu, non-cov2 viral genome assembly submission prep for NCBI/Genbank. 

Nextflow pipeline orchestrating:
- `SeqSender` fasta+metadata file validation and .src + .sbt file generation, optional automated Biosample submission over FTP
- `VADR` annotation and optional trimming terminal N's
- `tbl2asn` submission-ready .sqn file generation 

```mermaid
flowchart TB
  subgraph " "
    subgraph params
      v2["metadata"]
      v0["submission_name"]
      v5["vadr_models"]
      v1["config"]
      v3["fasta"]
    end
    v7([SEQSENDER])
    v9([VADR])
    v11([TABLE2ASN])
    v1 --> v7
    v2 --> v7
    v3 --> v7
    v5 --> v9
    v7 --> v9
    v7 --> v11
    v9 --> v11
  end

```

Currently in use for Measles virus, WNV, flexible to inlcude other viruses which have VADR model representation. 

## Requirements

## Usage

### Step 1
Clone the repository to wherever you typically run Nextflow:
`git clone https://github.com/DOH-KEW4303/VirGO.git`

### Step 2
Run the command to initiate the workflow, insterting the appropriate paths to your input files:
`nextflow run main.nf \
-profile docker \
--submission_name MeV_VSP010 \
--config seqsender_config2025.yaml \
--metadata /path/to/metadata/file/your_meta.csv \
--fasta /path/to/fasta/file/your_fasta.fa \
--organism OTHER \
--vadr_models /path/to/vadr-model/folder`
