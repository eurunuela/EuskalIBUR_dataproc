#$ -S /bin/bash
#$ -cwd
#$ -m be
#$ -M s.moia@bcbl.eu

module load singularity/3.3.0

##########################################################################################################################
##---START OF SCRIPT----------------------------------------------------------------------------------------------------##
##########################################################################################################################

date

wdr=/bcbl/home/public/PJMASK_2/EuskalIBUR_dataproc

cd ${wdr}

if [[ ! -d ../LogFiles ]]
then
	mkdir ../LogFiles
fi

qsub -q long.q -N "prep_001_EuskalIBUR" \
	 -o ${wdr}/../LogFiles/001_01_preproc_pipe \
	 -e ${wdr}/../LogFiles/001_01_preproc_pipe \
	 ${wdr}/98.hcp/run_full_preproc_pipeline.sh 001 01

# Run full preproc
joblist=""

for ses in $(seq -f %02g 1 10)
do
	rm ${wdr}/../LogFiles/001_${ses}_preproc_pipe
	qsub -q long.q -N "s_001_${ses}_EuskalIBUR" \
	-o ${wdr}/../LogFiles/001_${ses}_preproc_pipe \
	-e ${wdr}/../LogFiles/001_${ses}_preproc_pipe \
	${wdr}/98.hcp/run_full_preproc_pipeline.sh 001 ${ses}
	joblist=${joblist}s_001_${ses}_EuskalIBUR,
done

joblist=${joblist::-1}

for sub in 002 003 004 007 008 009
do
	for ses in $(seq -f %02g 1 10)
	do
		rm ${wdr}/../LogFiles/${sub}_${ses}_preproc_pipe
		qsub -q long.q -N "s_${sub}_${ses}_EuskalIBUR" \
		-o ${wdr}/../LogFiles/${sub}_${ses}_preproc_pipe \
		-e ${wdr}/../LogFiles/${sub}_${ses}_preproc_pipe \
		${wdr}/98.hcp/run_full_preproc_pipeline.sh ${sub} ${ses}
		# -hold_jid "${joblist}" \
	done
	joblist=""
	for ses in $(seq -f %02g 1 10)
	do
		joblist=${joblist}s_${sub}_${ses}_EuskalIBUR,
	done
	joblist=${joblist::-1}
done

# joblist=""

# for ses in $(seq -f %02g 1 10)
# do
# 	rm ${wdr}/../LogFiles/001_${ses}_pipe
# 	qsub -q long.q -N "s_001_${ses}_EuskalIBUR" \
# 	-o ${wdr}/../LogFiles/001_${ses}_pipe \
# 	-e ${wdr}/../LogFiles/001_${ses}_pipe \
# 	${wdr}/98.hcp/run_subject_pipeline.sh 001 ${ses}
# 	joblist=${joblist}s_001_${ses}_EuskalIBUR,
# done

# joblist=${joblist::-1}

# for sub in 004 007 008 009  # 002 003 004 007 008 009
# do
# 	for ses in $(seq -f %02g 1 10)
# 	do
# 		rm ${wdr}/../LogFiles/${sub}_${ses}_pipe
# 		qsub -q long.q -N "s_${sub}_${ses}_EuskalIBUR" \
# 		-o ${wdr}/../LogFiles/${sub}_${ses}_pipe \
# 		-e ${wdr}/../LogFiles/${sub}_${ses}_pipe \
# 		${wdr}/98.hcp/run_subject_pipeline.sh ${sub} ${ses}
# 		# -hold_jid "${joblist}" \
# 	done
# 	joblist=""
# 	for ses in $(seq -f %02g 1 10)
# 	do
# 		joblist=${joblist}s_${sub}_${ses}_EuskalIBUR,
# 	done
# 	joblist=${joblist::-1}
# done

# ### Plot pipeline for subjects parallel
# rm ${wdr}/../LogFiles/plot_cvrval_pipe
# qsub -q short.q -N "plot_EuskalIBUR" \
# -o ${wdr}/../LogFiles/plot_cvrval_pipe \
# -e ${wdr}/../LogFiles/plot_cvrval_pipe \
# ${wdr}/98.hcp/run_plot_pipeline.sh

# ### Third level pipeline
# rm ${wdr}/../LogFiles/third_level_pipe
# qsub -q long.q -N "third_level_EuskalIBUR" \
# -o ${wdr}/../LogFiles/third_level_pipe \
# -e ${wdr}/../LogFiles/third_level_pipe \
# ${wdr}/98.hcp/run_third_level_pipe.sh
# # -hold_jid "${joblist}" \
# # -hold_jid "${old_ftype}_EuskalIBUR" \
