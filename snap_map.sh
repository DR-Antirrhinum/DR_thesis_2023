#!/bin/bash -e

################################
#### MAP READS WITH BWA-MEM ####
################################

source bwa-0.7.17
source samtools-1.7
source jre-7.21
in_dir=Processing_CM_pools_30_Jan_19
AlignmentsDir=Processing_CM_pools_30_Jan_19/Alignments
ref=Ref_V4/Am_2019.fasta 
pic_path=/nbi/software/testing/picard/1.134/x86_64/jars/
GATK_path=/nbi/software/testing/GATK/3.5.0/x86_64/jars/
#source bamutil for clipoverlap
#source  bamutil-1.0.14

filepath_f1=$1
filepath_r2=$2
in_file_f1=$(basename $filepath_f1)
in_file_r2=$(basename $filepath_r2)

outfile=$(echo $in_file_f1 | cut -f 1 -d "." )

#-M for Picard compatibility
#-t threads
#-R Complete read group header line. ’\t’ can be used in STR and will be converted to a TAB in the output SAM. 
#The read group ID will be attached to every read in the output. An example is ’@RG\tID:foo\tSM:bar’. [null]

EX_READ=$(zcat $in_dir/$in_filepath_f1 | head -n 1)
ID=$(echo $EX_READ | cut -f3 -d ":")
FL=$(echo $EX_READ | cut -f4 -d ":")
RL=$(echo $EX_READ | cut -f10 -d ":")

srun bwa mem -M -t 8 -R "@RG\tID:${ID}.LANE${FL}\tSM:${outfile}\tLB:${outfile}\tPL:ILLUMINA\tPU:${ID}.${FL}.${RL}" $ref $in_dir/$filepath_f1 $in_dir/$filepath_r2 > $AlignmentsDir/$outfile.V4.bwa.sam

#########################################
#### SORT SAMFILE AND CONVERT TO BAM ####
#########################################

filepath=$AlignmentsDir/$outfile.V4.bwa.sam

samtools sort -@ 8 -o $AlignmentsDir/$outfile.V4.bwa.sorted.bam $filepath

rm $filepath

###################################################################
#### REMOVE PCR DUPLICATES AND LOCAL REALIGNMENT AROUND INDELS ####
###################################################################

filepath=$AlignmentsDir/$outfile.V4.bwa.sorted.bam

#Index sorted bamfile
srun samtools index $filepath

#remove PCR duplicates
srun java -Xmx16g -jar ${pic_path}/picard.jar MarkDuplicates REMOVE_DUPLICATES=true ASSUME_SORTED=true VALIDATION_STRINGENCY=SILENT MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=900 TMP_DIR=/tmp INPUT=$filepath OUTPUT=${AlignmentsDir}/${outfile}.V4.bwa.sorted.rmdup.bam  METRICS_FILE=${AlignmentsDir}/${outfile}.V4.bwa.sorted.rmdup.metrics

srun samtools index ${AlignmentsDir}/${outfile}.V4.bwa.sorted.rmdup.bam

#local realignment around indels
srun java -Xmx16g -jar ${GATK_path}/GenomeAnalysisTK.jar -T RealignerTargetCreator -R ${ref} -I ${AlignmentsDir}/${outfile}.V4.bwa.sorted.rmdup.bam -o ${AlignmentsDir}/${outfile}.V4.bwa.sorted.rmdup.realign.intervals

srun java -Xmx16g -jar  ${GATK_path}/GenomeAnalysisTK.jar -T IndelRealigner -R ${ref}  -targetIntervals ${AlignmentsDir}/${outfile}.V4.bwa.sorted.rmdup.realign.intervals -I ${AlignmentsDir}/${outfile}.V4.bwa.sorted.rmdup.bam --out ${AlignmentsDir}/${outfile}.V4.bwa.sorted.rmdup.realign.bam

srun samtools index ${AlignmentsDir}/${outfile}.V4.bwa.sorted.rmdup.realign.bam

