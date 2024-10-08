

#!/bin/bash

# Step 1: Download datasets
echo "Downloading datasets..."
wget https://raw.githubusercontent.com/josoga2/yt-dataset/main/dataset/raw_reads/reference.fasta

datasets=(ACBarrie Alsen Baxter Chara Drysdale)
for sample in "${datasets[@]}"; do
  wget https://github.com/josoga2/yt-dataset/raw/main/dataset/raw_reads/${sample}_R1.fastq.gz
  wget https://github.com/josoga2/yt-dataset/raw/main/dataset/raw_reads/${sample}_R2.fastq.gz
done

# Step 2: Quality control (FastQC)
echo "Running FastQC..."
fastqc *.fastq.gz

# Step 3: Trimming (FastP)
echo "Trimming reads..."
for sample in "${datasets[@]}"; do
  fastp -i ${sample}_R1.fastq.gz -I ${sample}_R2.fastq.gz -o ${sample}_R1_trimmed.fastq.gz -O ${sample}_R2_trimmed.fastq.gz
done

# Step 4: Index reference genome (bwa)
echo "Indexing reference genome..."
bwa index reference.fasta

# Step 5: Genome mapping (bwa)
echo "Mapping reads to reference..."
for sample in "${datasets[@]}"; do
  bwa mem reference.fasta ${sample}_R1_trimmed.fastq.gz ${sample}_R2_trimmed.fastq.gz > ${sample}.sam
done

# Step 6: Convert SAM to BAM, sort and index (samtools)
echo "Converting SAM to BAM and sorting..."
for sample in "${datasets[@]}"; do
  samtools view -S -b ${sample}.sam | samtools sort -o ${sample}_sorted.bam
  samtools index ${sample}_sorted.bam
done

# Step 7: Variant calling (bcftools)
echo "Calling variants..."
bcftools mpileup -f reference.fasta *.bam | bcftools call -mv -Ov -o variants.vcf

echo "Pipeline completed!"
