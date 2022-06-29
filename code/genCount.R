# Generate script for submitting STAR alignment job to EMLB cluster

library(tidyverse)

inputList = "./bamList.txt"
rawFolder = "/g/huber/projects/HAP1_phenotyping/data/pre-pilot/transcriptomics/aligned/deep_shallow_together/shallow_aligned/"
gtfFile= "/g/huber/projects/nct/cll/RawData/RNASeq/ReferenceGenome/GRCh38_Ensembl104/Homo_sapiens.GRCh38.104.gtf"
runTime = "4-00:00:00" #1 day
nThread = 1  #8 cores
nJob = 4 #four jobs in each script

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
                "#SBATCH --mail-user=jlu@embl.de")
  }
  
  header = c(header,"","module load HTSeq/0.9.1-foss-2016b-Python-2.7.12","",
             "module load pysam/0.10.0-foss-2016b-Python-2.7.12") #load module
  return(header)
}


#split jobs
jobList <- split(fastq, ceiling(seq_along(fastq)/nJob))

#generate script for each run
for (i in seq_along(jobList)) {
  fileConn<-file(sprintf("htseq/sub%s.sh",i))
  patID <- sapply(jobList[[i]], function(x) str_split(x,"[.]")[[1]][1])
  starCommand <- sapply(seq_along(jobList[[i]]), function(j) {
    c("",sprintf("htseq-count -f bam -s yes -r pos %s/%s %s > %s_counts.out", 
      rawFolder,jobList[[i]][j],gtfFile,patID[j]))
  })
  writeLines(c(genHeader(i),starCommand), con = fileConn)
  close(fileConn)
}

#generate script for submitting all jobs
fileConn <- file("htseq/subAll.sh")
allSub <- sapply(seq_along(jobList), function(i) {
  sprintf("sbatch sub%s.sh",i)
})
writeLines(allSub, fileConn)
close(fileConn)

