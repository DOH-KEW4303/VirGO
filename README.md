
<img width="636" height="454" alt="ChatGPT Image Feb 11, 2026, 03_30_32 PM" src="https://github.com/user-attachments/assets/d11ea5e3-20f4-432a-bf61-fdb8a1c4c625" />

# VirGO: Viral Genome Submission File Orchestration
Created for non-flu, non-cov2 viral genome assembly submission to NCBI/Genbank. 

Nextflow pipeline orchestrating:
- VADR annotation
- tbl2asn .sqn file generation 
- SeqSender fasta+metadata file validation and .src, .sbt file generation.

Initial baseline commit includes:
- main.nf
- nextflow.config

Currently in use for Measles virus, WNV, flexible to inlcude other viruses which have VADR model representation. 
