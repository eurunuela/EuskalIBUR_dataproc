#!/usr/bin/env bash

if_missing_do() {
if [ ! -e $3 ]
then
      printf "%s is missing, " "$3"
      case $1 in
            copy ) echo "copying $2"; cp $2 $3 ;;
            mask ) echo "binarising $2"; fslmaths $2 -bin $3 ;;
            * ) "and you shouldn't see this"; exit ;;
      esac
fi
}

ftype=${1:-optcom}
lastses=${2:-10}
wdr=${3:-/data}
tmp=${4:-/tmp}

### Main ###
cwd=$( pwd )
cd ${wdr} || exit

echo "Creating folders"
if [ ! -d CVR_reliability ]
then
	mkdir CVR_reliability
fi

cd CVR_reliability

mkdir reg normalised cov

# Copy files for transformation & create mask
if_missing_do copy /scripts/90.template/MNI152_T1_1mm_brain_resamp_2.5mm.nii.gz ./reg/MNI_T1_brain.nii.gz
if_missing_do mask ./reg/MNI_T1_brain.nii.gz ./reg/MNI_T1_brain_mask.nii.gz

# Copy
for sub in $( seq -f %03g 1 10 )
do
	if [[ ${sub} == 005 || ${sub} == 006 || ${sub} == 010 ]]
	then
		continue
	fi

	echo "%%% Working on subject ${sub} %%%"

	echo "Preparing transformation"
	if_missing_do copy ${wdr}/sub-${sub}/ses-01/reg/sub-${sub}_ses-01_acq-uni_T1w2std1Warp.nii.gz \
			  ./reg/${sub}_T1w2std1Warp.nii.gz
	if_missing_do copy ${wdr}/sub-${sub}/ses-01/reg/sub-${sub}_ses-01_acq-uni_T1w2std0GenericAffine.mat \
	              ./reg/${sub}_T1w2std0GenericAffine.mat
	if_missing_do copy ${wdr}/sub-${sub}/ses-01/reg/sub-${sub}_ses-01_T2w2sub-${sub}_sbref0GenericAffine.mat \
	              ./reg/${sub}_T2w2sbref0GenericAffine.mat
	if_missing_do copy ${wdr}/sub-${sub}/ses-01/reg/sub-${sub}_ses-01_T2w2sub-${sub}_ses-01_acq-uni_T1w0GenericAffine.mat \
	              ./reg/${sub}_T2w2T1w0GenericAffine.mat

	for map in simple # masked_physio_only  # corrected
	do
		for ses in $( seq -f %02g 1 ${lastses} )
		do
			echo "Copying session ${ses} ${map}"
			imcp ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_${map}.nii.gz \
				 ./${sub}_${ses}_${ftype}_cvr_${map}.nii.gz
			if [ ${map} != "simple" ]
			then
				imcp ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_lag_${map}.nii.gz \
					 ./${sub}_${ses}_${ftype}_lag_${map}.nii.gz
			fi
			imcp ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_tmap_${map}.nii.gz \
				 ./${sub}_${ses}_${ftype}_tmap_${map}.nii.gz

			for inmap in cvr lag tmap  # cvr_idx_mask tstat_mask
			do
				inmap=${inmap}_${map}
				if [ ${inmap} != "lag_simple" ]
				then
					echo "Transforming ${inmap} maps of session ${ses} to MNI"
					antsApplyTransforms -d 3 -i ${sub}_${ses}_${ftype}_${inmap}.nii.gz -r ./reg/MNI_T1_brain.nii.gz \
										-o ./normalised/std_${ftype}_${inmap}_${sub}_${ses}.nii.gz -n NearestNeighbor \
										-t ./reg/${sub}_T1w2std1Warp.nii.gz \
										-t ./reg/${sub}_T1w2std0GenericAffine.mat \
										-t ./reg/${sub}_T2w2T1w0GenericAffine.mat \
										-t [./reg/${sub}_T2w2sbref0GenericAffine.mat,1]
					imrm ${sub}_${ses}_${ftype}_${inmap}.nii.gz
				fi
			done
		done
	done
done

cd normalised


# Compute ICC
inmap=cvr_simple

rm ../ICC_${inmap}_${ftype}_GM_only.nii.gz

3dICC -prefix ../ICC_${inmap}_${ftype}_GM_only.nii.gz -jobs 10                                    \
      -mask ${wdr}/Surr_reliability/MNI_GM.nii.gz                                                \
      -model  '1+(1|session)+(1|Subj)'                                                     \
      -dataTable                                                                           \
      Subj session  InputFile                     \
      001  01       std_${ftype}_${inmap}_001_01.nii.gz \
      001  02       std_${ftype}_${inmap}_001_02.nii.gz \
      001  03       std_${ftype}_${inmap}_001_03.nii.gz \
      001  04       std_${ftype}_${inmap}_001_04.nii.gz \
      001  05       std_${ftype}_${inmap}_001_05.nii.gz \
      001  06       std_${ftype}_${inmap}_001_06.nii.gz \
      001  07       std_${ftype}_${inmap}_001_07.nii.gz \
      001  08       std_${ftype}_${inmap}_001_08.nii.gz \
      001  09       std_${ftype}_${inmap}_001_09.nii.gz \
      001  10       std_${ftype}_${inmap}_001_10.nii.gz \
      002  01       std_${ftype}_${inmap}_002_01.nii.gz \
      002  02       std_${ftype}_${inmap}_002_02.nii.gz \
      002  03       std_${ftype}_${inmap}_002_03.nii.gz \
      002  04       std_${ftype}_${inmap}_002_04.nii.gz \
      002  05       std_${ftype}_${inmap}_002_05.nii.gz \
      002  06       std_${ftype}_${inmap}_002_06.nii.gz \
      002  07       std_${ftype}_${inmap}_002_07.nii.gz \
      002  08       std_${ftype}_${inmap}_002_08.nii.gz \
      002  09       std_${ftype}_${inmap}_002_09.nii.gz \
      002  10       std_${ftype}_${inmap}_002_10.nii.gz \
      003  01       std_${ftype}_${inmap}_003_01.nii.gz \
      003  02       std_${ftype}_${inmap}_003_02.nii.gz \
      003  03       std_${ftype}_${inmap}_003_03.nii.gz \
      003  04       std_${ftype}_${inmap}_003_04.nii.gz \
      003  05       std_${ftype}_${inmap}_003_05.nii.gz \
      003  06       std_${ftype}_${inmap}_003_06.nii.gz \
      003  07       std_${ftype}_${inmap}_003_07.nii.gz \
      003  08       std_${ftype}_${inmap}_003_08.nii.gz \
      003  09       std_${ftype}_${inmap}_003_09.nii.gz \
      003  10       std_${ftype}_${inmap}_003_10.nii.gz \
      004  01       std_${ftype}_${inmap}_004_01.nii.gz \
      004  02       std_${ftype}_${inmap}_004_02.nii.gz \
      004  03       std_${ftype}_${inmap}_004_03.nii.gz \
      004  04       std_${ftype}_${inmap}_004_04.nii.gz \
      004  05       std_${ftype}_${inmap}_004_05.nii.gz \
      004  06       std_${ftype}_${inmap}_004_06.nii.gz \
      004  07       std_${ftype}_${inmap}_004_07.nii.gz \
      004  08       std_${ftype}_${inmap}_004_08.nii.gz \
      004  09       std_${ftype}_${inmap}_004_09.nii.gz \
      004  10       std_${ftype}_${inmap}_004_10.nii.gz \
      007  01       std_${ftype}_${inmap}_007_01.nii.gz \
      007  02       std_${ftype}_${inmap}_007_02.nii.gz \
      007  03       std_${ftype}_${inmap}_007_03.nii.gz \
      007  04       std_${ftype}_${inmap}_007_04.nii.gz \
      007  05       std_${ftype}_${inmap}_007_05.nii.gz \
      007  06       std_${ftype}_${inmap}_007_06.nii.gz \
      007  07       std_${ftype}_${inmap}_007_07.nii.gz \
      007  08       std_${ftype}_${inmap}_007_08.nii.gz \
      007  09       std_${ftype}_${inmap}_007_09.nii.gz \
      007  10       std_${ftype}_${inmap}_007_10.nii.gz \
      008  01       std_${ftype}_${inmap}_008_01.nii.gz \
      008  02       std_${ftype}_${inmap}_008_02.nii.gz \
      008  03       std_${ftype}_${inmap}_008_03.nii.gz \
      008  04       std_${ftype}_${inmap}_008_04.nii.gz \
      008  05       std_${ftype}_${inmap}_008_05.nii.gz \
      008  06       std_${ftype}_${inmap}_008_06.nii.gz \
      008  07       std_${ftype}_${inmap}_008_07.nii.gz \
      008  08       std_${ftype}_${inmap}_008_08.nii.gz \
      008  09       std_${ftype}_${inmap}_008_09.nii.gz \
      008  10       std_${ftype}_${inmap}_008_10.nii.gz \
      009  01       std_${ftype}_${inmap}_009_01.nii.gz \
      009  02       std_${ftype}_${inmap}_009_02.nii.gz \
      009  03       std_${ftype}_${inmap}_009_03.nii.gz \
      009  04       std_${ftype}_${inmap}_009_04.nii.gz \
      009  05       std_${ftype}_${inmap}_009_05.nii.gz \
      009  06       std_${ftype}_${inmap}_009_06.nii.gz \
      009  07       std_${ftype}_${inmap}_009_07.nii.gz \
      009  08       std_${ftype}_${inmap}_009_08.nii.gz \
      009  09       std_${ftype}_${inmap}_009_09.nii.gz \
      009  10       std_${ftype}_${inmap}_009_10.nii.gz

echo "End of script!"

cd ${cwd}