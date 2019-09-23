#!/usr/bin/env bash

######### Motion cleaning for PJMASK
# Author:  Stefano Moia
# Version: 1.0
# Date:    15.08.2019
#########

wdr=/media
# wdr=/media/nemo/ANVILData/gdrive/PJMASK

### Main ###
cwd=$( pwd )
cd ${wdr}

mkdir ME_Denoising

cd ME_Denoising

for sub in 002 003 007
do
	mkdir sub-${sub}
	for ses in $( seq -f %02g 1 9 )
	do
		flpr=sub-${sub}_ses-${ses}
		cp ${wdr}/preproc/sub-${sub}/ses-${ses}/func_preproc/${flpr}_task-breathhold_echo-1_bold_dvars.par sub-${sub}/dvars_pre_sub-${sub}_ses-${ses}.1D
		# cp ${wdr}/preproc/sub-${sub}/ses-${ses}/func_preproc/${flpr}_task-breathhold_echo-1_bold_dvars_pre.par sub-${sub}/dvars_pre_sub-${sub}_ses-${ses}.1D
		cp ${wdr}/preproc/sub-${sub}/ses-${ses}/func_preproc/${flpr}_task-breathhold_echo-1_bold_fd.par sub-${sub}/fd_sub-${sub}_ses-${ses}.1D

		fsl_motion_outliers -i ${wdr}/preproc/sub-${sub}/ses-${ses}/00.${flpr}_task-breathhold_optcom_bold_native_preprocessed \
		-o tmp_out -s dvars_optcom_sub-${sub}_ses-${ses}.1D --dvars --nomoco
		fsl_motion_outliers -i ${wdr}/preproc/sub-${sub}/ses-${ses}/00.${flpr}_task-breathhold_echo-2_bold_native_preprocessed \
		-o tmp_out -s dvars_echo-2_sub-${sub}_ses-${ses}.1D --dvars --nomoco
		fsl_motion_outliers -i ${wdr}/preproc/sub-${sub}/ses-${ses}/${flpr}_task-breathhold_meica_bold_bet \
		-o tmp_out -s dvars_meica_sub-${sub}_ses-${ses}.1D --dvars --nomoco
	done
done

# add call to python!

