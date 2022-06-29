### This folder contains R scripts used for generating the slurm scripts for submitting jobs to the EMBL cluster.

__genAlign_salmon_QuantSeq.R__ : generating slurm scripts for Salmon workflow to get count data.

__genAlign_star_QuantSeq.R__ : generating slurm scripts for STAR to map RNAseq reads to the genome.

__genCount.R__ : generating slurm scripts for HTseq to count RNAseq reads based on the output bam files from STAR.

__featureCount_batch4.R__ : generating slurm scripts for featureCounts as an alternative read assignment or mapping tool

__genFastQC.R__ : generating slurm scripts for fastQC. 

__fastqFiles.txt__ : Input fastq file lists used as input for the above scripts. 
