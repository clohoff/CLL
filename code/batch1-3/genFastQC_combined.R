# Generate script for submitting FastQC alignment job to EMLB cluster

library(tidyverse)

inputList = "~/Documents/R/drugseq_test/data/bamList_batch1.txt"
rawFolder = "/g/huber/projects/nct/cll/ProcessedData/RNAseq/drugSeq/bam/batch1_combined"
outFolder = "/g/huber/projects/nct/cll/ProcessedData/RNAseq/drugSeq/fastQC/batch1_combined"
runTime = "07:00:00" #seven hours
nThread = 1  #number of cores per node
nJob = 20    #number of jobs in each script

### Cluster Usage Report ###
#Cores: 1
#CPU Utilized: 00:24:30
#CPU Efficiency: 100.00% of 00:24:30 core-walltime --> 08:00:00 next time
#Job Wall-clock time: 00:24:30
#Memory Utilized: 239.95 MB
#Memory Efficiency: 39.99% of 600.00 MB --> 400MB next time

#read in file list
fastq <- readLines(inputList)

#function to generate the header for script
genHeader <- function(i, email = FALSE) {
  header <- c("#!/bin/bash",
            sprintf("#SBATCH -J fastQC_%s",i),
            sprintf("#SBATCH -t %s",runTime),
            sprintf("#SBATCH -n %s",nThread),
            "#SBATCH --mem=600MB",
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
    c("",sprintf("fastqc %s/%s -o %s -f bam",
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
