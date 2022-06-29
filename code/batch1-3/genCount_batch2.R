# Generate script for submitting gene count job for batch 2 to EMLB cluster

library(tidyverse)

inputList = "./data/bamList_batch2.txt"
rawFolder = "/g/huber/projects/nct/cll/ProcessedData/RNAseq/drugSeq/bam/batch2"
gtfFile= "/g/huber/projects/nct/cll/RawData/RNASeq/ReferenceGenome/GRCh38_Ensembl104/Homo_sapiens.GRCh38.104.gtf" #Human reference genome
runTime = "06:00:00" #6 hours
nThread = 1  #number of cores
nJob = 8  #number of jobs in each script

### Cluster usage report ###
# 237 samples in total, divided into 4 jobs per bash script
#Cores: 1
#CPU Utilized: 00:58:16
#CPU Efficiency: 99.63% of 00:58:29 core-walltime
#Memory Utilized: 187.96 MB
#Memory Efficiency: 2.29% of 8.00 GB
# next time: increase time and put 20 jobs per script


#read in file list
fastq <- readLines(inputList)

#function to generate the header for script
genHeader <- function(i, email = FALSE) {
  header <- c("#!/bin/bash",
            sprintf("#SBATCH -J count_%s",i),
            sprintf("#SBATCH -t %s",runTime),
            sprintf("#SBATCH -n %s",nThread),
            "#SBATCH --mem=8G",
            sprintf("#SBATCH -o slurm_%s.out",i),
            sprintf("#SBATCH -e slurm_%s.err",i))
  if (email == TRUE) {
    header <- c(header,
                "#SBATCH --mail-type=END,FAIL",
                "#SBATCH --mail-user=caroline.lohoff@embl.de")
  }

  header = c(header,"","module load HTSeq/0.9.1-foss-2016b-Python-2.7.12","",
             "module load pysam/0.10.0-foss-2016b-Python-2.7.12") #load module
  return(header)
}


#split jobs
jobList <- split(fastq, ceiling(seq_along(fastq)/nJob))

#generate script for each run
for (i in seq_along(jobList)) {
  fileConn<-file(sprintf("sub%s.sh",i))
  patID <- sapply(jobList[[i]], function(x) str_split(x,"[.]")[[1]][1])
  starCommand <- sapply(seq_along(jobList[[i]]), function(j) {
    c("",sprintf("htseq-count -f bam -s yes -r pos %s/%s %s > %s_counts.out",
      rawFolder,jobList[[i]][j],gtfFile,patID[j]))
  })
  writeLines(c(genHeader(i),starCommand), con = fileConn)
  close(fileConn)
}

#generate script for submitting all jobs
fileConn <- file("subAll.sh")
allSub <- sapply(seq_along(jobList), function(i) {
  sprintf("sbatch sub%s.sh",i)
})
writeLines(allSub, fileConn)
close(fileConn)
