# Generate script for submitting STAR alignment job to EMLB cluster

library(tidyverse)

inputList = "./data/fastqFiles_batch4.txt"
rawFolder = "/g/huber/projects/nct/cll/RawData/RNASeq/drugSeq/batch4"
refGenome = "/g/huber/projects/nct/cll/RawData/RNASeq/ReferenceGenome/GRCh38_Ensembl104/star2.7.9a/"
runTime = "02:00:00" # two hours
nThread = 4  #4 cores per node
nJob = 10 #number of jobs in each script

### Cluster Usage Report ###
# 225 samples divided into 10 jobs per bash script
#Nodes: 1
#Cores per node: 4
#CPU Utilized: 01:35:08
#CPU Efficiency: 56.83% of 02:47:24 core-walltime
#Job Wall-clock time: 00:41:51
#Memory Utilized: 28.28 GB
#Memory Efficiency: 88.38% of 32.00 GB


#read in file list
fastq <- readLines(inputList)

#function to generate the header for script
genHeader <- function(i, email = FALSE) {
  header <- c("#!/bin/bash",
            sprintf("#SBATCH -J align_%s",i),
            sprintf("#SBATCH -t %s",runTime),
            sprintf("#SBATCH -n %s",nThread),
            "#SBATCH --mem=32GB",
            sprintf("#SBATCH -o slurm_%s.out",i),
            sprintf("#SBATCH -e slurm_%s.err",i))
  if (email == TRUE) {
    header <- c(header,
                "#SBATCH --mail-type=END,FAIL",
                "#SBATCH --mail-user=caroline.lohoff@embl.de")
  }

  header = c(header,"","module load STAR/2.7.9a-GCC-10.3.0") #load module
  return(header)
}


#split jobs
jobList <- split(fastq, ceiling(seq_along(fastq)/nJob))

#generate script for each run
for (i in seq_along(jobList)) {
  fileConn<-file(sprintf("sub%s.sh",i))
  patID <- sapply(jobList[[i]], function(x) str_split(x,"[.]")[[1]][1])
  starCommand <- sapply(seq_along(jobList[[i]]), function(j) {
    c("",sprintf("cp %s/%s $TMPDIR", rawFolder,jobList[[i]][j]),
      "cd $TMPDIR",
      sprintf("STAR --runThreadN %s --outBAMsortingThreadN %s --genomeDir %s --readFilesIn %s --outFileNamePrefix %s --outSAMtype BAM SortedByCoordinate --readFilesCommand zcat",
      nThread, nThread, refGenome, jobList[[i]][j],patID[j]),
      sprintf("mv *.bam ${SLURM_SUBMIT_DIR}"),
      sprintf("mv *Log.final.out ${SLURM_SUBMIT_DIR}/log/"),
      sprintf("rm %s", jobList[[i]][j]),
      "")
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
