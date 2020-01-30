#!/usr/bin/env bash

ftype=${1:-optcom}
wdr=${3:-/data}

### Main ###
cwd=$( pwd )
cd ${wdr} || exit

echo "Creating folders"
if [ ! -d 00.IEEE ]
then
	mkdir 00.IEEE
fi

cd 00.IEEE

mkdir reg

# Copy files for transformation
cp /scripts/MNI_T1_putamen_cerebellum.nii.gz ./reg/.
cp /scripts/MNI152_T1_1mm_brain.nii.gz ./reg/MNI_T1_brain_1mm.nii.gz
cp /scripts/MNI152_T1_1mm_brain_resamp_2.5mm.nii.gz ./reg/MNI_T1_brain.nii.gz

# Copy
for sub in $( seq -f %03g 1 10 )
do
	if [[ ${sub} == 05 || ${sub} == 06 ]]
	then
		continue
	fi

	echo "%%% Working on subject ${sub} %%%"

	echo "Preparing transformation"
	# this has to be simplified
	imcp ${wdr}/sub-${sub}/ses-01/reg/sub-${sub}_sbref_brain.nii.gz \
		 ./reg/${sub}_sbref_brain.nii.gz
	imcp ${wdr}/sub-${sub}/ses-01/reg/sub-${sub}_sbref_brain_mask.nii.gz \
		 ./reg/${sub}_sbref_brain_mask.nii.gz
	imcp ${wdr}/sub-${sub}/ses-01/reg/sub-${sub}_ses-01_acq-uni_T1w2std1InverseWarp.nii.gz \
		 ./reg/${sub}_T1w2std1InverseWarp.nii.gz
	imcp ${wdr}/sub-${sub}/ses-01/reg/sub-${sub}_ses-01_acq-uni_T1w2std1Warp.nii.gz \
		 ./reg/${sub}_T1w2std1Warp.nii.gz
	cp ${wdr}/sub-${sub}/ses-01/reg/sub-${sub}_ses-01_acq-uni_T1w2std0GenericAffine.mat \
	   ./reg/${sub}_T1w2std0GenericAffine.mat
	cp ${wdr}/sub-${sub}/ses-01/reg/sub-${sub}_ses-01_T2w2sub-${sub}_sbref0GenericAffine.mat \
	   ./reg/${sub}_T2w2sbref0GenericAffine.mat
	cp ${wdr}/sub-${sub}/ses-01/reg/sub-${sub}_ses-01_T2w2sub-${sub}_ses-01_acq-uni_T1w0GenericAffine.mat \
	   ./reg/${sub}_T2w2T1w0GenericAffine.mat

	echo "Transforming putamen to SBRef"
	antsApplyTransforms -d 3 -i ./reg/MNI_T1_putamen_cerebellum.nii.gz -r ./reg/${sub}_sbref_brain.nii.gz \
						-o ./reg/${sub}_CVR_segmentation.nii.gz -n MultiLabel \
						-t ./reg/${sub}_T2w2sbref0GenericAffine.mat \
						-t [./reg/${sub}_T2w2T1w0GenericAffine.mat,1] \
						-t [./reg/${sub}_T1w2std0GenericAffine.mat,1] \
						-t ./reg/${sub}_T1w2std1InverseWarp.nii.gz

	for ses in 04
	do
		echo "Copying session ${ses}"
		imcp ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr.nii.gz \
			 ./${sub}_${ses}_${ftype}_cvr.nii.gz
		imcp ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_idx_mask.nii.gz \
			 ./${sub}_${ses}_${ftype}_cvr_idx_mask.nii.gz
		imcp ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_lag.nii.gz \
			 ./${sub}_${ses}_${ftype}_cvr_lag.nii.gz
		imcp ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_tmap.nii.gz \
			 ./${sub}_${ses}_${ftype}_tmap.nii.gz
		imcp ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_tmap_abs_mask.nii.gz \
			 ./${sub}_${ses}_${ftype}_tstat_mask.nii.gz

		echo "Extracting bulk shift maps"
		fslroi ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_betas_time.nii.gz \
			   ./${sub}_${ses}_${ftype}_cvr_bulkshift.nii.gz 29 1
		fslroi ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_tstat_time.nii.gz \
			   ./${sub}_${ses}_${ftype}_tmap_bulkshift.nii.gz 29 1

		for inmap in cvr cvr_idx_mask cvr_lag tmap tstat_mask cvr_bulkshift tmap_bulkshift
		do
			echo "Transforming ${inmap} maps of session ${ses} to MNI"
			infile=${sub}_${ses}_${ftype}_${inmap}.nii.gz
			antsApplyTransforms -d 3 -i ${infile} -r ./reg/MNI_T1_brain.nii.gz \
								-o ./reg/std_${infile}.nii.gz -n NearestNeighbor \
								-t ./reg/${sub}_T1w2std1Warp.nii.gz \
								-t ./reg/${sub}_T1w2std0GenericAffine.mat \
								-t ./reg/${sub}_T2w2T1w0GenericAffine.mat \
								-t [./reg/${sub}_T2w2sbref0GenericAffine.mat,1]
		done
	done
done

cd reg

mkdir bulkshift
mv std*bulkshift* bulkshift/.

mkdir ICC
mv std*cvr.nii* ICC/.
mv std*cvr_lag* ICC/.
mv std*tmap* ICC/.

cd bulkshift/

for map in cvr tmap
do
	fslmerge -t std_${map}_bulkshift $(ls std*${map}*)
	fslmaths std_${map}_bulkshift -Tmean avg_std_${map}_bulkshift
	imrm std_${map}_bulkshift
done

cd ../ICC

for map in cvr.nii.gz cvr_lag tmap
do
fslmerge -t std_${map} $(ls std*${map}*)
fslmaths std_${map} -Tmean avg_std_${map}
imrm std_${map}
done



cd ${cwd}