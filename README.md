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
