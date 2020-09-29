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

for parc in flowterritories schaefer-100 # aparc flowterritories schaefer-100
do
	rm ${wdr}/../LogFiles/cvr_${parc}_pipe
	qsub -q veryshort.q -N "cvr_${parc}_EuskalIBUR" -o ${wdr}/../LogFiles/cvr_${parc}_pipe -e ${wdr}/../LogFiles/cvr_${parc}_pipe ${wdr}/98.hcp/run_cvrparc_pipeline.sh ${parc}
done

for r in $(seq 2 2 120)
do
	parc=rand-${r}
	rm ${wdr}/../LogFiles/cvr_${parc}_pipe
	qsub -q veryshort.q -N "cvr_${parc}_EuskalIBUR" -o ${wdr}/../LogFiles/cvr_${parc}_pipe -e ${wdr}/../LogFiles/cvr_${parc}_pipe ${wdr}/98.hcp/run_cvrparc_pipeline.sh ${parc}
done

# for sub in 001 002 003 004 005 006 007 008 009 010
# do
# 	rm ${wdr}/../LogFiles/${sub}_motor_pipe
# 	qsub -q long.q -N "m_${sub}_01_EuskalIBUR" -o ${wdr}/../LogFiles/${sub}_motor_pipe -e ${wdr}/../LogFiles/${sub}_motor_pipe ${wdr}/98.hcp/run_subject_pipeline.sh ${sub} 01
# 	qsub -q long.q -N "m_${sub}_01_EuskalIBUR" -o ${wdr}/../LogFiles/${sub}_motor_pipe -e ${wdr}/../LogFiles/${sub}_motor_pipe ${wdr}/98.hcp/run_subject_pipeline.sh ${sub} 02
# done

# joblist=""

# for ses in $(seq -f %02g 1 10)
# do
# 	rm ${wdr}/../LogFiles/001_${ses}_pipe
# 	qsub -q long.q -N "s_001_${ses}_EuskalIBUR" -o ${wdr}/../LogFiles/001_${ses}_pipe -e ${wdr}/../LogFiles/001_${ses}_pipe ${wdr}/98.hcp/run_subject_pipeline.sh 001 ${ses}
# 	joblist=${joblist}s_001_${ses}_EuskalIBUR,
# done

# joblist=${joblist::-1}

# for sub in 002 003 004 007 008 009
# do
# 	for ses in $(seq -f %02g 1 10)
# 	do
# 		rm ${wdr}/../LogFiles/${sub}_${ses}_pipe
# 		qsub -q long.q -hold_jid "${joblist}" -N "s_${sub}_${ses}_EuskalIBUR" -o ${wdr}/../LogFiles/${sub}_${ses}_pipe -e ${wdr}/../LogFiles/${sub}_${ses}_pipe ${wdr}/98.hcp/run_subject_pipeline.sh ${sub} ${ses}
# 		# qsub -q long.q -N "s_${sub}_${ses}_EuskalIBUR" -o ${wdr}/../LogFiles/${sub}_${ses}_pipe -e ${wdr}/../LogFiles/${sub}_${ses}_pipe ${wdr}/98.hcp/run_subject_pipeline.sh ${sub} ${ses}
# 	done
# 	joblist=""
# 	for ses in $(seq -f %02g 1 10)
# 	do
# 		joblist=${joblist}s_${sub}_${ses}_EuskalIBUR,
# 	done
# 	joblist=${joblist::-1}
# done

# ftype=optcom
# rm ${wdr}/../LogFiles/${ftype}_pipe
# qsub -q long.q -N "${ftype}_EuskalIBUR" -o ${wdr}/../LogFiles/${ftype}_pipe -e ${wdr}/../LogFiles/${ftype}_pipe ${wdr}/98.hcp/run_cvr_reliability.sh ${ftype}
# # qsub -q long.q -hold_jid "${joblist}" -N "${ftype}_EuskalIBUR" -o ${wdr}/../LogFiles/${ftype}_pipe -e ${wdr}/../LogFiles/${ftype}_pipe ${wdr}/98.hcp/run_cvr_reliability.sh ${ftype}
# old_ftype=${ftype}
# joblist=${ftype}_EuskalIBUR

# for ftype in meica-aggr meica-orth meica-cons echo-2
# do
# 	rm ${wdr}/../LogFiles/${ftype}_pipe
# 	qsub -q long.q -hold_jid "${old_ftype}_EuskalIBUR" -N "${ftype}_EuskalIBUR" -o ${wdr}/../LogFiles/${ftype}_pipe -e ${wdr}/../LogFiles/${ftype}_pipe ${wdr}/98.hcp/run_cvr_reliability.sh ${ftype}
# 	old_ftype=${ftype}
# done

# rm ${wdr}/../LogFiles/motion_pipe
# qsub -q short.q -N "mot_EuskalIBUR" -o ${wdr}/../LogFiles/motion_pipe -e ${wdr}/../LogFiles/motion_pipe ${wdr}/98.hcp/run_motion_plot.sh
# qsub -q short.q -hold_jid "${joblist}" -N "mot_EuskalIBUR" -o ${wdr}/../LogFiles/motion_pipe -e ${wdr}/../LogFiles/motion_pipe ${wdr}/98.hcp/run_motion_plot.sh

# rm ${wdr}/../LogFiles/plot_pipe
# qsub -q short.q -N "plot_EuskalIBUR" -o ${wdr}/../LogFiles/plot_pipe -e ${wdr}/../LogFiles/plot_pipe ${wdr}/98.hcp/run_plot_pipeline.sh
# qsub -q short.q -hold_jid "${joblist}" -N "plot_EuskalIBUR" -o ${wdr}/../LogFiles/plot_pipe -e ${wdr}/../LogFiles/plot_pipe ${wdr}/98.hcp/run_plot_pipeline.sh

# qsub -q short.q -N "s_010_11_prep" -o ${wdr}/../LogFiles/010_11_pipe -e ${wdr}/../LogFiles/010_11_pipe ${wdr}/tmp.preproc_10.sh

# rm ${wdr}/../LogFiles/third_level_pipe
# qsub -q short.q -N "third_level_EuskalIBUR" -o ${wdr}/../LogFiles/third_level_pipe -e ${wdr}/../LogFiles/third_level_pipe ${wdr}/98.hcp/run_third_level_pipe.sh
# qsub -q short.q -hold_jid "${old_ftype}_EuskalIBUR" -N "third_level_EuskalIBUR" -o ${wdr}/../LogFiles/third_level_pipe -e ${wdr}/../LogFiles/third_level_pipe ${wdr}/98.hcp/run_third_level_pipe.sh