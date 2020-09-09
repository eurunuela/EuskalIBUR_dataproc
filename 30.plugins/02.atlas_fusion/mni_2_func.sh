#!/bin/bash
#$ -cwd
#$ -o out.txt
#$ -e err.txt
#$ -m be
#$ -M v.ferrer@bcbl.eu
#$ -N mni2func
#$ -S /bin/bash
if [[ -z "${PRJDIR}" ]]; then
  if [[ ! -z "$1" ]]; then
     PRJDIR=$1
  else
     echo "You need to input PROJECT DIRECTORY (PRJDIR) as ENVIRONMENT VARIABLE or $1"
     exit
  fi
fi
if [[ -z "${SUBJ}" ]]; then
  if [[ ! -z "$2" ]]; then
     SUBJ=$2
  else
     echo "You need to input SUBJECT (SUBJ) as ENVIRONMENT VARIABLE or $2"
     exit
  fi
fi

func_ref=$PRJDIR/in_dir/$SUBJ
FS_aparc=/Data/${SUBJ}/ses-01/atlas/${SUBJ}_aparc.a2009s+aseg.nii.gz
tmp_dir=/Data/tmp_fuse

if [[ -d $tmp_dir ]]; then
	echo ""
else
	mkdir -p $tmp_dir
fi
tmp_dir=/Data/tmp_fuse/${SUBJ}
if [[ -d $tmp_dir ]]; then
	echo ""
else
	mkdir -p ${tmp_dir}
fi 

cd ${tmp_dir}
echo 'create anatomical masks'
echo -e "\e[32m ++ INFO: Create mask of lateral ventricles...\e[39m"
3dcalc -overwrite -a ${FS_aparc} -datum byte -prefix FS_Vent.nii.gz -expr 'amongst(a,4,43)'
echo -e "\e[32m ++ INFO: Create mask of white matter...\e[39m"
3dcalc -overwrite -a ${FS_aparc} -datum byte -prefix FS_WM.nii.gz -expr 'amongst(a,2,7,41,46,251,252,253,254,255)'
echo -e "\e[32m ++ INFO: Create mask of grey matter cerebellum...\e[39m"
3dcalc -overwrite -a ${FS_aparc} -datum byte -prefix FS_Cerebellum.nii.gz -expr 'amongst(a,8,47)'
echo -e "\e[32m ++ INFO: Create mask of left hemisphere based on aseg...\e[39m"
3dcalc -overwrite -a ${FS_aparc} -b lh.ribbon.nii.gz -datum byte \
  -prefix FS_Lh_mask.nii.gz -expr 'bool(b + amongst(a,2,4,5,7,8,9,10,11,12,13,17,18,19,20,26,27,28))'
3dmask_tool -overwrite -fill_holes -dilate_input 2 -2 -input FS_Lh_mask.nii.gz -prefix FS_Lh_mask.nii.gz
echo -e "\e[32m ++ INFO: Create mask of right hemisphere based on aseg...\e[39m"
3dcalc -overwrite -overwrite -a ${FS_aparc} -b rh.ribbon.nii.gz -datum byte \
  -prefix FS_Rh_mask.nii.gz -expr 'bool(b + amongst(a,41,43,44,45,46,47,48,49,50,51,52,53,54,55,56,58,59,60))'
3dmask_tool -overwrite -fill_holes -dilate_input 2 -2 -input FS_Rh_mask.nii.gz -prefix FS_Rh_mask.nii.gz
echo -e "\e[32m ++ INFO: Create mask of subcortical structures...\e[39m"
3dcalc -overwrite -a ${FS_aparc} -datum byte -prefix FS_Subcortical.nii.gz -expr 'amongst(a,9,10,11,12,13,17,18,19,20,26,27,28,48,49,50,51,52,53,54,55,56,58,59,60)'
echo -e "\e[32m ++ INFO: Create mask of GM voxels...\e[39m"
3dcalc -overwrite -a lh.ribbon.nii.gz -b rh.ribbon.nii.gz -c FS_Cerebellum.nii.gz -d FS_Subcortical.nii.gz -expr 'bool(a+b+c+d)' -prefix FS_GM.nii.gz
cd $PRE_DIR

# parcels_sizes=(100 400 1000)
# for parcels in 
Atlas_yeo=$PRJDIR/in_dir/Schaefer2018_400Parcels_17Networks_order_FSLMNI152_1mm_not_resampled.nii.gz
# transform yeo atlas from MNI to T1 space
antsApplyTransforms -d 3 -i $Atlas_yeo \
					-r /Data/${SUBJ}/ses-01/anat_preproc/${SUBJ}_ses-01_acq-uni_T1w_brain.nii.gz -o ${tmp_dir}/Yeo_atlas2${SUBJ}_ANAT.nii.gz \
-n Multilabel -t [/Data/${SUBJ}/ses-01/${SUBJ}_ses-01_acq-uni_T1w2std0GenericAffine.mat ,1] -t /Data/${SUBJ}/ses-01/${SUBJ}_ses-01_acq-uni_T1w2std1InverseWarp.nii.gz

# Fuse subcorticals into yeo atlas
3dcalc -overwrite -a -o ${tmp_dir}/Yeo_atlas2${SUBJ}_ANAT.nii.gz -b FS_GM.al_epi.FUNC.nii.gz -c aparc.a2009s+aseg.al_epi.FUNC.nii.gz -d FS_Subcortical.al_epi.FUNC.nii.gz  -expr "a+(c+400-a*b)*d" -prefix Yeo_atlas_subcorticals2${SUBJ}_ANAT.nii.gz

# transform yeo atlas+subcorticals from T1 to functional space
antsApplyTransforms -d 3 -i $Atlas_yeo \
					-r Yeo_atlas_subcorticals2${SUBJ}_ANAT.nii.gz -o ${tmp_dir}/Yeo_atlas2${SUBJ}_FUNC.nii.gz \
-n Multilabel -t [/Data/${SUBJ}/ses-01/${SUBJ}_ses-01_T2w2${SUBJ}_sbref0GenericAffine.mat] -t [/Data/${SUBJ}/ses-01/${SUBJ}_ses-01_T2w2${SUBJ}_ses-01_acq-uni_T1w0GenericAffine.mat,1]

