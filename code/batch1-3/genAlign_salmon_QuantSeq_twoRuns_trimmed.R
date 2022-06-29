# Generate script for submitting STAR alignment job to EMLB cluster

# Both fastq files of batch 1 and batch 1 new will be combined

library(tidyverse)

inputList = "~/Documents/R/drugseq_test/data/fastqFiles_batch1.txt"

rawFolder1 = "/g/huber/projects/nct/cll/RawData/RNASeq/drugSeq/batch1"
rawFolder2 = "/g/huber/projects/nct/cll/RawData/RNASeq/drugSeq/batch1_new"

runTime = "7:00:00" #8 hours
nThread = 8  #8 cores
nJob = 5 #five jobs in each script
alignMode = "A"
trimmLength = 12


### Information about run ###
#Nodes: 1
#Cores per node: 8
#CPU Utilized: 02:01:29  --> next time 7 hours
#CPU Efficiency: 73.66% of 02:44:56 core-walltime
#Memory Utilized: 5.60 GB
#Memory Efficiency: 70.04% of 8.00 GB --> next time 7 GB




#function to change file name between the two runs
fixName <- function(x) {
  x_new <- str_replace(x, "HMCKNBBXY", "HMC5GBBXY") %>%
    str_replace("-1-1_Lu", "-1-2_Lu") %>%
    str_replace("lane812dot2P", "lane8122P")
}

#read in file list

fastq <- readLines(inputList)

#function to generate the header for script
genHeader <- function(i, email = FALSE) {
  header <- c("#!/bin/bash",
            sprintf("#SBATCH -J align_%s",i),
            sprintf("#SBATCH -t %s",runTime),
            sprintf("#SBATCH -n %s",nThread),
            "#SBATCH --mem=7G",
            sprintf("#SBATCH -o slurm_%s.out",i),
            sprintf("#SBATCH -e slurm_%s.err",i))
  if (email == TRUE) {
    header <- c(header,
                "#SBATCH --mail-type=END,FAIL",
                "#SBATCH --mail-user=caroline.lohoff@embl.de")
  }

  header = c(header,"","module load Salmon/0.8.2-foss-2016b","module load cutadapt/3.4-GCCcore-10.2.0-Python-3.8.6") #load modules
  return(header)
}


#split jobs
jobList <- split(fastq, ceiling(seq_along(fastq)/nJob))

#generate script for each run
for (i in seq_along(jobList)) {
  fileConn<-file(sprintf("sub%s.sh",i))
  patID <- sapply(jobList[[i]], function(x) str_split(x,"[.]")[[1]][1])
  starCommand <- sapply(seq_along(jobList[[i]]), function(j) {
    f1 <- jobList[[i]][[j]]
    f2 <- fixName(jobList[[i]][[j]])
    c("",
      sprintf("cp %s/%s ${TMPDIR}", rawFolder1, f1),
      sprintf("cp %s/%s ${TMPDIR}", rawFolder2, f2),
      "cd $TMPDIR",
      sprintf("cutadapt -u %s -o %s_trimmed.fastq.gz %s",
              trimmLength, patID[j], jobList[[i]][[j]]),
      sprintf("cutadapt -u %s -o %s_trimmed.fastq.gz %s",
              trimmLength, fixName(patID[j]), fixName(jobList[[i]][j])),
      sprintf("salmon quant -i /g/huber/projects/nct/cll/ProcessedData/RNAseq/salmon_index/transcripts_index -l %s -r %s %s -p %s -o %s --gcBias",
      alignMode,f1,f2, nThread, patID[j]),
      sprintf("mv %s ${SLURM_SUBMIT_DIR}",patID[j]),
      sprintf("rm %s", jobList[[i]][j]),
      sprintf("rm %s", fixName(jobList[[i]][j])))
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
