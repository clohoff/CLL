# Generate script for submitting FastQC alignment job to EMLB cluster

library(tidyverse)

inputList = "./data/fastqFiles_batch4.txt"
rawFolder = "/g/huber/projects/nct/cll/RawData/RNASeq/drugSeq/batch4"
outFolder = "/g/huber/projects/nct/cll/ProcessedData/RNAseq/drugSeq/fastQC/batch4"
runTime = "08:30:00" #eight hours
nThread = 1  #number of cores per node
nJob = 40    #number of jobs in each script

### Cluster Usage Report ###
# 225 samples divided into 40 samples per bash script.
#Cores: 1
#CPU Utilized: 00:27:49
#CPU Efficiency: 41.82% of 01:06:31 core-walltime
#Job Wall-clock time: 01:06:31
#Memory Utilized: 221.95 MB
#Memory Efficiency: 44.39% of 500.00 MB

#read in file list
fastq <- readLines(inputList)

#function to generate the header for script
genHeader <- function(i, email = FALSE) {
  header <- c("#!/bin/bash",
            sprintf("#SBATCH -J fastQC_%s",i),
            sprintf("#SBATCH -t %s",runTime),
            sprintf("#SBATCH -n %s",nThread),
            "#SBATCH --mem=500MB",
            sprintf("#SBATCH -o slurm_%s.out",i),
            sprintf("#SBATCH -e slurm_%s.err",i))
  if (email == TRUE) {
    header <- c(header,
                "#SBATCH --mail-type=END,FAIL",
                "#SBATCH --mail-user=caroline.lohoff@embl.de")
  }

  header = c(header,"","module load FastQC/0.11.5-Java-1.8.0_112") #load module
  return(header)
}


#split jobs
jobList <- split(fastq, ceiling(seq_along(fastq)/nJob))

#generate script for each run
for (i in seq_along(jobList)) {
  fileConn<-file(sprintf("sub%s.sh",i))
  patID <- sapply(jobList[[i]], function(x) str_split(x,"_")[[1]][2])
  starCommand <- sapply(seq_along(jobList[[i]]), function(j) {
    c("",sprintf("fastqc %s/%s -o %s",
      rawFolder,jobList[[i]][j],outFolder))
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
