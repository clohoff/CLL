# Generate script for submitting STAR alignment job to EMLB cluster

library(tidyverse)

inputList = "./fastqFiles.txt"
rawFolder = "/g/huber/projects/HAP1_phenotyping/data/pre-pilot/transcriptomics/raw/shallow_RNAseq"
runTime = "5-00:00:00" #five days
nThread = 8  #8 cores
nJob = 2 #four jobs in each script
alignMode = "A"
trimmLength = 12

#read in file list

fastq <- readLines(inputList)

#function to generate the header for script
genHeader <- function(i, email = FALSE) {
  header <- c("#!/bin/bash",
            sprintf("#SBATCH -J align_%s",i),
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
  
  header = c(header,"","module load Salmon/0.8.2-foss-2016b","module load cutadapt/3.4-GCCcore-10.2.0-Python-3.8.6") #load module
  return(header)
}


#split jobs
jobList <- split(fastq, ceiling(seq_along(fastq)/nJob))

#generate script for each run
for (i in seq_along(jobList)) {
  fileConn<-file(sprintf("sub%s.sh",i))
  patID <- sapply(jobList[[i]], function(x) str_split(x,"[.]")[[1]][1])
  starCommand <- sapply(seq_along(jobList[[i]]), function(j) {
    c("",
      sprintf("cp %s/%s ${TMPDIR}", rawFolder, jobList[[i]][[j]]),
      "cd $TMPDIR",
      sprintf("cutadapt -u %s -o %s_trimmed.fastq.gz %s", 
              trimmLength, patID[j], jobList[[i]][j]),
      sprintf("salmon quant -i /g/huber/projects/nct/cll/ProcessedData/RNAseq/salmon_index/transcripts_index -l %s -r %s_trimmed.fastq.gz -p %s -o %s --gcBias", 
      alignMode,patID[j],nThread, patID[j]),
      sprintf("mv %s ${SLURM_SUBMIT_DIR}",patID[j]),
      sprintf("rm %s", jobList[[i]][j]))
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

