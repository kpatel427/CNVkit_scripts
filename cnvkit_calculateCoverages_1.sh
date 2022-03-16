#!/usr/bin/bash
#SBATCH --job-name=cnvkitTN
#SBATCH --cpus-per-task=2
#SBATCH -a 1-62
#SBATCH --mem=64G
#SBATCH -t 72:00:00

# SCRIPT TO CALCULATE COVERAGE FOR ALL SAMPLES

bam_dir="~/SingleCell/WGS/BAM/bwa"

# activate env
echo "Activating environment..."
source activate py36

function cnvPipeline () {

echo "Grepping files..."
#for LINE in $LINES
#do
    files_arr=$(ls ${bam_dir} | grep "${1}.*bam$")
#done


echo "Converting output into array..."
array=($files_arr)



echo "Calculating Coverages..."

for i in "${!array[@]}"
	do

		echo ${array[$i]}
		out_name=$(echo ${array[$i]} | sed 's/.readgroup.sorted.bam//')

		cnvkit.py coverage ${bam_dir}/${array[$i]} ../data/allGenes_target.bed -o ../results/$out_name.targetcoverage.cnn
		cnvkit.py coverage ${bam_dir}/${array[$i]} ../data/allGenes_antitargets.bed -o ../results/$out_name.antitargetcoverage.cnn
		
	done

}

IFS=$'\n' read -d '' -r -a LINES < ../data/allSamples.txt
# calling function and assigning jobs from arrays to cluster
cnvPipeline ${LINES[$SLURM_ARRAY_TASK_ID-1]}
echo "Done!"
