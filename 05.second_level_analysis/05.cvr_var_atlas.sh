#!/usr/bin/env bash

ftype=$1
lastses=${2:-5}
wdr=${3:-/data}

cwd=$( pwd )

echo "Creating folders"
if [ ! -d ${wdr}/CVR/00.Reliability ]
then
	mkdir ${wdr}/CVR/00.Reliability
fi

cd ${wdr}/CVR/00.Reliability

for sub in 001 002 003 004 007
do
	adir=${wdr}/sub-${sub}/ses-01/anat
	rdir=${wdr}/sub-${sub}/ses-01/reg
	aparc=${adir}/sub-${sub}_ses-01_aparc2009

	atlas=${cwd}/Schaefer2018_400Parcels_17Networks_order_FSLMNI152_1mm
	mref=${rdir}/sub-${sub}_sbref_brain

	if [ ! -e sub-${sub}_atlas.nii.gz ]
	then
		echo -e "Create mask of grey matter cerebellum"
		3dcalc -overwrite -a ${aparc}.nii.gz -datum byte -prefix tmp.sub-${sub}_cerebellum_mask.nii.gz -expr 'amongst(a,8,47)'
		echo -e "Create mask of subcortical structures"
		3dcalc -overwrite -a ${aparc}.nii.gz -datum byte -prefix tmp.sub-${sub}_subcortical_mask.nii.gz -expr 'amongst(a,9,10,11,12,13,17,18,19,20,26,27,28,48,49,50,51,52,53,54,55,56,58,59,60)'

		antsApplyTransforms -d 3 -i ${adir}_preproc/sub-${sub}_ses-01_acq-uni_T1w_GM.nii.gz -r ${mref}.nii.gz \
							-o sub-${sub}_GM_mask.nii.gz -n MultiLabel \
							-t ${rdir}/sub-${sub}_ses-01_T2w2sub-${sub}_sbref0GenericAffine.mat \
							-t [${rdir}/sub-${sub}_ses-01_T2w2sub-${sub}_ses-01_acq-uni_T1w0GenericAffine.mat,1]

		antsApplyTransforms -d 3 -i tmp.sub-${sub}_cerebellum_mask.nii.gz -r ${mref}.nii.gz \
							-o sub-${sub}_cerebellum_mask.nii.gz -n MultiLabel \
							-t ${rdir}/sub-${sub}_ses-01_T2w2sub-${sub}_sbref0GenericAffine.mat \
							-t [${rdir}/sub-${sub}_ses-01_T2w2sub-${sub}_ses-01_acq-uni_T1w0GenericAffine.mat,1]

		antsApplyTransforms -d 3 -i tmp.sub-${sub}_subcortical_mask.nii.gz -r ${mref}.nii.gz \
							-o sub-${sub}_subcortical_mask.nii.gz -n MultiLabel \
							-t ${rdir}/sub-${sub}_ses-01_T2w2sub-${sub}_sbref0GenericAffine.mat \
							-t [${rdir}/sub-${sub}_ses-01_T2w2sub-${sub}_ses-01_acq-uni_T1w0GenericAffine.mat,1]

		antsApplyTransforms -d 3 -i ${aparc}.nii.gz -r ${mref}.nii.gz \
							-o sub-${sub}_aparc.nii.gz -n MultiLabel \
							-t ${rdir}/sub-${sub}_ses-01_T2w2sub-${sub}_sbref0GenericAffine.mat \
							-t [${rdir}/sub-${sub}_ses-01_T2w2sub-${sub}_ses-01_acq-uni_T1w0GenericAffine.mat,1]

		antsApplyTransforms -d 3 -i ${atlas}.nii.gz -r ${mref}.nii.gz \
							-o sub-${sub}_atlas.nii.gz -n Multilabel \
							-t ${rdir}/sub-${sub}_ses-01_T2w2sub-${sub}_sbref0GenericAffine.mat \
							-t [${rdir}/sub-${sub}_ses-01_T2w2sub-${sub}_ses-01_acq-uni_T1w0GenericAffine.mat,1] \
							-t [${rdir}/sub-${sub}_ses-01_acq-uni_T1w2std0GenericAffine.mat,1] \
							-t ${rdir}/sub-${sub}_ses-01_acq-uni_T1w2std1InverseWarp.nii.gz

		3dcalc -overwrite -a sub-${sub}_atlas.nii.gz -b sub-${sub}_GM_mask.nii.gz \
			   -c sub-${sub}_aparc.nii.gz -d sub-${sub}_subcortical_mask.nii.gz \
			   -e ${mref}_mask.nii.gz \
			   -expr "(a+(c+400-a*b)*d)*e" -prefix sub-${sub}_atlas.nii.gz
	fi

	echo "Making hypervolume for CoV"

	for cvr_type in cvr cvr_simple cvr_lag tmap
	do
		for ses in $( seq -f %02g 1 ${lastses} )
		do
			imcp ../sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_${cvr_type} \
				 tmp.sub-${sub}_${ftype}_${cvr_type}_ses-${ses}
		done

		fslmerge -t tmp.sub-${sub}_${ftype}_${cvr_type} tmp.sub-${sub}_${ftype}_${cvr_type}_*
		fslmaths tmp.sub-${sub}_${ftype}_${cvr_type} -Tmean tmp.sub-${sub}_${ftype}_${cvr_type}_mean
		fslmaths tmp.sub-${sub}_${ftype}_${cvr_type} -Tstd \
				 -div tmp.sub-${sub}_${ftype}_${cvr_type}_mean sub-${sub}_${ftype}_${cvr_type}_CoV
		fslmeants -i sub-${sub}_${ftype}_${cvr_type}_CoV \
				  -o sub-${sub}_${ftype}_${cvr_type}_CoV_atlas.1D \
				  --label=sub-${sub}_atlas.nii.gz
	done

	# The following is for 3dICC
	# for ses in $( seq -f %02g 1 ${lastses} )
	# do
	# 	echo "Extracting info session ${ses}"
	# 	fslmeants -i ../sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr \
	# 			  -o tmp.sub-${sub}_ses-${ses}_${ftype}_cvr.1D \
	# 			  --label=sub-${sub}_atlas.nii.gz
	# 	fslmeants -i ../sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_simple \
	# 			  -o tmp.sub-${sub}_ses-${ses}_${ftype}_cvr_simple.1D \
	# 			  --label=sub-${sub}_atlas.nii.gz
	# 	fslmeants -i ../sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_lag \
	# 			  -o tmp.sub-${sub}_ses-${ses}_${ftype}_cvr_lag.1D \
	# 			  --label=sub-${sub}_atlas.nii.gz
	# 	fslmeants -i ../sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_tmap \
	# 			  -o tmp.sub-${sub}_ses-${ses}_${ftype}_tmap.1D \
	# 			  --label=sub-${sub}_atlas.nii.gz
	# 	nvox=$( csvtool -t SPACE width tmp.sub-${sub}_ses-${ses}_${ftype}_cvr.1D )
	# 	let nvox--
	# 	echo "${nvox}"
	# 	fslascii2img tmp.sub-${sub}_ses-${ses}_${ftype}_cvr.1D \
	# 				 ${nvox} 1 1 1 1 1 1 1 \
	# 				 ${sub}_${ses}_${ftype}_cvr.nii.gz
	# 	fslascii2img tmp.sub-${sub}_ses-${ses}_${ftype}_cvr_simple.1D \
	# 				 ${nvox} 1 1 1 1 1 1 1 \
	# 				 ${sub}_${ses}_${ftype}_cvr_simple.nii.gz
	# 	fslascii2img tmp.sub-${sub}_ses-${ses}_${ftype}_cvr_lag.1D \
	# 				 ${nvox} 1 1 1 1 1 1 1 \
	# 				 ${sub}_${ses}_${ftype}_cvr_lag.nii.gz
	# 	fslascii2img tmp.sub-${sub}_ses-${ses}_${ftype}_tmap.1D \
	# 				 ${nvox} 1 1 1 1 1 1 1 \
	# 				 ${sub}_${ses}_${ftype}_tmap.nii.gz
	# done
done

# 3dICC -prefix ${ftype}_ICC_cvr.nii.gz -jobs 6                                    \
#       -model '1+(1|Subj)+(1|session)'                                            \
#       -tStat 'tFile'                                                             \
#       -dataTable                                                                 \
#       Subj   session        InputFile                      tFile                 \
#       001    01        001_01_${ftype}_cvr.nii.gz    001_01_${ftype}_tmap.nii.gz \
#       001    02        001_02_${ftype}_cvr.nii.gz    001_02_${ftype}_tmap.nii.gz \
#       001    03        001_03_${ftype}_cvr.nii.gz    001_03_${ftype}_tmap.nii.gz \
#       001    04        001_04_${ftype}_cvr.nii.gz    001_04_${ftype}_tmap.nii.gz \
#       001    05        001_05_${ftype}_cvr.nii.gz    001_05_${ftype}_tmap.nii.gz \
#       002    01        002_01_${ftype}_cvr.nii.gz    002_01_${ftype}_tmap.nii.gz \
#       002    02        002_02_${ftype}_cvr.nii.gz    002_02_${ftype}_tmap.nii.gz \
#       002    03        002_03_${ftype}_cvr.nii.gz    002_03_${ftype}_tmap.nii.gz \
#       002    04        002_04_${ftype}_cvr.nii.gz    002_04_${ftype}_tmap.nii.gz \
#       002    05        002_05_${ftype}_cvr.nii.gz    002_05_${ftype}_tmap.nii.gz \
#       003    01        003_01_${ftype}_cvr.nii.gz    003_01_${ftype}_tmap.nii.gz \
#       003    02        003_02_${ftype}_cvr.nii.gz    003_02_${ftype}_tmap.nii.gz \
#       003    03        003_03_${ftype}_cvr.nii.gz    003_03_${ftype}_tmap.nii.gz \
#       003    04        003_04_${ftype}_cvr.nii.gz    003_04_${ftype}_tmap.nii.gz \
#       003    05        003_05_${ftype}_cvr.nii.gz    003_05_${ftype}_tmap.nii.gz \
#       004    01        004_01_${ftype}_cvr.nii.gz    004_01_${ftype}_tmap.nii.gz \
#       004    02        004_02_${ftype}_cvr.nii.gz    004_02_${ftype}_tmap.nii.gz \
#       004    03        004_03_${ftype}_cvr.nii.gz    004_03_${ftype}_tmap.nii.gz \
#       004    04        004_04_${ftype}_cvr.nii.gz    004_04_${ftype}_tmap.nii.gz \
#       004    05        004_05_${ftype}_cvr.nii.gz    004_05_${ftype}_tmap.nii.gz  #\
#       # 007    01        007_01_${ftype}_cvr.nii.gz    007_01_${ftype}_tmap.nii.gz \
#       # 007    02        007_02_${ftype}_cvr.nii.gz    007_02_${ftype}_tmap.nii.gz \
#       # 007    03        007_03_${ftype}_cvr.nii.gz    007_03_${ftype}_tmap.nii.gz \
#       # 007    04        007_04_${ftype}_cvr.nii.gz    007_04_${ftype}_tmap.nii.gz \
#       # 007    05        007_05_${ftype}_cvr.nii.gz    007_05_${ftype}_tmap.nii.gz

# 3dICC -prefix ${ftype}_ICC_cvr_simple.nii.gz -jobs 6                                    \
#       -model '1+(1|Subj)+(1|session)'                                                   \
#       -tStat 'tFile'                                                                    \
#       -dataTable                                                                        \
#       Subj   session        InputFile                      tFile                        \
#       001    01        001_01_${ftype}_cvr_simple.nii.gz    001_01_${ftype}_tmap.nii.gz \
#       001    02        001_02_${ftype}_cvr_simple.nii.gz    001_02_${ftype}_tmap.nii.gz \
#       001    03        001_03_${ftype}_cvr_simple.nii.gz    001_03_${ftype}_tmap.nii.gz \
#       001    04        001_04_${ftype}_cvr_simple.nii.gz    001_04_${ftype}_tmap.nii.gz \
#       001    05        001_05_${ftype}_cvr_simple.nii.gz    001_05_${ftype}_tmap.nii.gz \
#       002    01        002_01_${ftype}_cvr_simple.nii.gz    002_01_${ftype}_tmap.nii.gz \
#       002    02        002_02_${ftype}_cvr_simple.nii.gz    002_02_${ftype}_tmap.nii.gz \
#       002    03        002_03_${ftype}_cvr_simple.nii.gz    002_03_${ftype}_tmap.nii.gz \
#       002    04        002_04_${ftype}_cvr_simple.nii.gz    002_04_${ftype}_tmap.nii.gz \
#       002    05        002_05_${ftype}_cvr_simple.nii.gz    002_05_${ftype}_tmap.nii.gz \
#       003    01        003_01_${ftype}_cvr_simple.nii.gz    003_01_${ftype}_tmap.nii.gz \
#       003    02        003_02_${ftype}_cvr_simple.nii.gz    003_02_${ftype}_tmap.nii.gz \
#       003    03        003_03_${ftype}_cvr_simple.nii.gz    003_03_${ftype}_tmap.nii.gz \
#       003    04        003_04_${ftype}_cvr_simple.nii.gz    003_04_${ftype}_tmap.nii.gz \
#       003    05        003_05_${ftype}_cvr_simple.nii.gz    003_05_${ftype}_tmap.nii.gz \
#       004    01        004_01_${ftype}_cvr_simple.nii.gz    004_01_${ftype}_tmap.nii.gz \
#       004    02        004_02_${ftype}_cvr_simple.nii.gz    004_02_${ftype}_tmap.nii.gz \
#       004    03        004_03_${ftype}_cvr_simple.nii.gz    004_03_${ftype}_tmap.nii.gz \
#       004    04        004_04_${ftype}_cvr_simple.nii.gz    004_04_${ftype}_tmap.nii.gz \
#       004    05        004_05_${ftype}_cvr_simple.nii.gz    004_05_${ftype}_tmap.nii.gz  #\
#       # 007    01        007_01_${ftype}_cvr_simple.nii.gz    007_01_${ftype}_tmap.nii.gz \
#       # 007    02        007_02_${ftype}_cvr_simple.nii.gz    007_02_${ftype}_tmap.nii.gz \
#       # 007    03        007_03_${ftype}_cvr_simple.nii.gz    007_03_${ftype}_tmap.nii.gz \
#       # 007    04        007_04_${ftype}_cvr_simple.nii.gz    007_04_${ftype}_tmap.nii.gz \
#       # 007    05        007_05_${ftype}_cvr_simple.nii.gz    007_05_${ftype}_tmap.nii.gz

# 3dICC -prefix ${ftype}_ICC_cvr_lag.nii.gz -jobs 6                                    \
#       -model '1+(1|Subj)+(1|session)'                                                \
#       -tStat 'tFile'                                                                 \
#       -dataTable                                                                     \
#       Subj   session        InputFile                      tFile                     \
#       001    01        001_01_${ftype}_cvr_lag.nii.gz    001_01_${ftype}_tmap.nii.gz \
#       001    02        001_02_${ftype}_cvr_lag.nii.gz    001_02_${ftype}_tmap.nii.gz \
#       001    03        001_03_${ftype}_cvr_lag.nii.gz    001_03_${ftype}_tmap.nii.gz \
#       001    04        001_04_${ftype}_cvr_lag.nii.gz    001_04_${ftype}_tmap.nii.gz \
#       001    05        001_05_${ftype}_cvr_lag.nii.gz    001_05_${ftype}_tmap.nii.gz \
#       002    01        002_01_${ftype}_cvr_lag.nii.gz    002_01_${ftype}_tmap.nii.gz \
#       002    02        002_02_${ftype}_cvr_lag.nii.gz    002_02_${ftype}_tmap.nii.gz \
#       002    03        002_03_${ftype}_cvr_lag.nii.gz    002_03_${ftype}_tmap.nii.gz \
#       002    04        002_04_${ftype}_cvr_lag.nii.gz    002_04_${ftype}_tmap.nii.gz \
#       002    05        002_05_${ftype}_cvr_lag.nii.gz    002_05_${ftype}_tmap.nii.gz \
#       003    01        003_01_${ftype}_cvr_lag.nii.gz    003_01_${ftype}_tmap.nii.gz \
#       003    02        003_02_${ftype}_cvr_lag.nii.gz    003_02_${ftype}_tmap.nii.gz \
#       003    03        003_03_${ftype}_cvr_lag.nii.gz    003_03_${ftype}_tmap.nii.gz \
#       003    04        003_04_${ftype}_cvr_lag.nii.gz    003_04_${ftype}_tmap.nii.gz \
#       003    05        003_05_${ftype}_cvr_lag.nii.gz    003_05_${ftype}_tmap.nii.gz \
#       004    01        004_01_${ftype}_cvr_lag.nii.gz    004_01_${ftype}_tmap.nii.gz \
#       004    02        004_02_${ftype}_cvr_lag.nii.gz    004_02_${ftype}_tmap.nii.gz \
#       004    03        004_03_${ftype}_cvr_lag.nii.gz    004_03_${ftype}_tmap.nii.gz \
#       004    04        004_04_${ftype}_cvr_lag.nii.gz    004_04_${ftype}_tmap.nii.gz \
#       004    05        004_05_${ftype}_cvr_lag.nii.gz    004_05_${ftype}_tmap.nii.gz  #\
#       # 007    01        007_01_${ftype}_cvr_lag.nii.gz    007_01_${ftype}_tmap.nii.gz \
#       # 007    02        007_02_${ftype}_cvr_lag.nii.gz    007_02_${ftype}_tmap.nii.gz \
#       # 007    03        007_03_${ftype}_cvr_lag.nii.gz    007_03_${ftype}_tmap.nii.gz \
#       # 007    04        007_04_${ftype}_cvr_lag.nii.gz    007_04_${ftype}_tmap.nii.gz \
#       # 007    05        007_05_${ftype}_cvr_lag.nii.gz    007_05_${ftype}_tmap.nii.gz

rm tmp.sub-*

cd ${cwd}