#!/usr/bin/bash
#SBATCH --job-name=cnvkit
#SBATCH --mem=16G
#SBATCH -t 10:00:00


# activate env
echo "Activating environment..."
source activate py36

# target step
# splitting the larger and unequal target regions into average bin size
# target = genic regions
# target average size of at least 1000 bases for 30x coverage, or proportionally more for lower-coverage sequencing.
cnvkit.py target my_target_regions.bed --annotate refFlat.txt --split --target-avg-size 1000 -o my_targets.bed

# antitarget step 
# using the target bed file generated in previous step and using accesible genomic regions to generate an off-target bed file
cnvkit.py access hg38.fa -o access.hg38.bed
cnvkit.py antitarget my_targets.bed -g access.hg38.bed -o my_antitargets.bed

# coverage step
# calculating coverages for all Samples - Tumor and normal
cnvkit.py coverage Tumor.bam my_targets.bed -o Tumor.targetcoverage.cnn
cnvkit.py coverage Tumor.bam my_antitargets.bed -o Tumor.antitargetcoverage.cnn

cnvkit.py coverage Normal.bam my_targets.bed -o Normal.targetcoverage.cnn
cnvkit.py coverage Normal.bam my_antitargets.bed -o Normal.antitargetcoverage.cnn

# reference step
# Pooling all normal samples to generate a reference profile
# If fasta genome file is provided, GC and Repeat masked fraction bias corrections are performed for each bin
cnvkit.py reference *Normal.{,anti}targetcoverage.cnn --fasta hg38.fa -o my_reference.cnn

# fix step
# Using the reference for each tumor sample
# Combine the uncorrected target and antitarget coverage tables (.cnn) and correct for biases in regional coverage and GC content, according to the given reference. 
# Output a table of copy number ratios (.cnr).
cnvkit.py fix Tumor.targetcoverage.cnn Tumor.antitargetcoverage.cnn my_reference.cnn -o Tumor.cnr

# segment step
# calling segme ntation algorithm on copy ratios
# Infer discrete copy number segments from the given coverage table
cnvkit.py segment -m flasso Tumor.cnr -o Tumor.cns

# call step
# Given segmented log2 ratio estimates (.cns), derive each segment’s absolute integer copy number using either
# The output is another .cns file, with an additional “cn” column listing each segment’s absolute integer copy number
cnvkit.py call Tumor.cns -o Tumor.call.cns



# ---------------------------- OR ----------------------------------------- #

cnvkit.py batch Sample1.bam Sample2.bam -n Control1.bam Control2.bam \
        -m wgs -f hg38.fasta --annotate refFlat.txt


# This command uses the given reference genome’s sequencing-accessible regions (“access” BED) as the “targets” – these will be calculated on the fly if not provided. No “antitarget” regions are used.





