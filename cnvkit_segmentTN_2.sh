#!/usr/bin/bash
#SBATCH --job-name=cnvkitTN
#SBATCH --cpus-per-task=2
#SBATCH -a 1-41
#SBATCH --mem=64G
#SBATCH -t 72:00:00

# SCRIPT TO CALL SEGMENTS USING MATCHED TUMOR-NORMAL

bam_dir="~/SingleCell/WGS/BAM/bwa"
cnn_files="~/results"


# activate env
echo "Activating environment..."
source activate py36

function cnvPipeline () {

	# grep tumor .cnn file
	files_arr=$(ls ${cnn_files} | grep "${1}.*targetcoverage.cnn$")

	# grep matched normal .cnn file
	matched_normal=$(ls ${cnn_files}/*.targetcoverage.cnn | grep $(cat ~/WGS_treatment_pairs_with_normal.txt | grep ${1} | cut -f3))
	base_name_normal=$(basename ${matched_normal})
	echo $base_sample_name


	echo "Converting output into array..."
	array=($files_arr)

	echo "matched normal= $matched_normal"
	echo $files_arr


	echo "Making segment calls..."

	for i in "${!array[@]}"
	do

		echo ${array[$i]}
		base_sample_name=$(echo ${array[$i]} | sed 's/.targetcoverage.cnn//g')
		base_sample_name=$(echo $base_sample_name | sed 's/.ant//g')

		echo $base_sample_name

		# fix
		echo "fix samples..."
		cnvkit.py fix ${cnn_files}/${base_sample_name}.targetcoverage.cnn ${cnn_files}/${base_sample_name}.antitargetcoverage.cnn ${cnn_files}/${base_name_normal} -o ${cnn_files}/${base_sample_name}.cnr

		# segment
		echo "segmentation..."
		cnvkit.py segment ${cnn_files}/${base_sample_name}.cnr -o ${cnn_files}/${base_sample_name}.cns

		# call - consistent tumor purity
		echo "call segments..."
		cnvkit.py call ${cnn_files}/${base_sample_name}.cns -o ${cnn_files}/${base_sample_name}.call.cns
	
	done

}

IFS=$'\n' read -d '' -r -a LINES < ../data/tumors.txt
# calling function and assigning jobs from arrays to cluster
cnvPipeline ${LINES[$SLURM_ARRAY_TASK_ID-1]}
echo "Done!"
