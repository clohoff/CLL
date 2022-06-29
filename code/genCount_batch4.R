# Generate script for submitting gene count job for batch 4 to EMLB cluster

library(tidyverse)

inputList = "data/bamList_batch4.txt"
rawFolder = "/g/huber/projects/nct/cll/ProcessedData/RNAseq/drugSeq/bam/batch4"
gtfFile= "/g/huber/projects/nct/cll/ProcessedData/RNAseq/drugSeq/htseq/Homo_sapiens_UTR.GRCh38.104.gtf"
runTime = "10:00:00" #10 hours
nThread = 1  #number of cores
nJob = 20  #number of jobs in each script

#read in file list
fastq <- readLines(inputList)

#function to generate the header for script
genHeader <- function(i, email = FALSE) {
  header <- c("#!/bin/bash",
            sprintf("#SBATCH -J count_%s",i),
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

  header = c(header,"","module load HTSeq/0.9.1-foss-2016b-Python-2.7.12","",
             "module load pysam/0.10.0-foss-2016b-Python-2.7.12")
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
