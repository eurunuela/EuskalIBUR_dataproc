#!/usr/bin/env bash


sub=$1
ses=$2
TR=${3:-1.5}
wdr=${4:-/data}

### Main ###
cwd=$( pwd )

cd ${wdr} || exit

if [[ ! -d "decomp" ]]
then
	cd ${cwd}
	03.data_preproc/01.sheet_preproc.sh ${sub}
	cd ${wdr}
fi

echo "Denoising sub ${sub} ses ${ses} optcom"
fdir=${wdr}/sub-${sub}/ses-${ses}/func_preproc
flpr=sub-${sub}_ses-${ses}
meica_fldr=${fdir}/${flpr}_task-breathhold_concat_bold_bet_meica
meica_mix=${meica_fldr}/ica_mixing.tsv

sbrf=${wdr}/sub-${sub}/ses-01/func_preproc/sub-${sub}_ses-01_task-breathhold_rec-magnitude_echo-1_sbref
func=${fdir}/${flpr}_task-breathhold_optcom_bold_bet
bold=${flpr}_task-breathhold

cd decomp || exit

# 01.1. Processing list of classified components
acc=$( cat ${flpr}_accepted_list.1D )
rej=$( cat ${flpr}_rejected_list.1D )
ves=$( cat ${flpr}_vessels_list.1D )
net=$( cat ${flpr}_networks_list.1D )

# 01.2. Process rejected
1dcat "$meica_mix[$acc$net$ves]" > tmp.${flpr}_meica_good.1D
1dcat "$meica_mix[$rej]" > ${flpr}_rejected.1D

# 01.3. Orthogonalise them
1dtranspose ${flpr}_rejected.1D > tmp.${flpr}_meica_rej.1D
3dTproject -ort tmp.${flpr}_meica_good.1D -polort -1 -prefix tmp.${flpr}_tr.1D -input tmp.${flpr}_meica_rej.1D -overwrite
1dtranspose tmp.${flpr}_tr.1D > ${flpr}_rejected_ort.1D

# 01.4. Process rejected and vessels
1dcat "$meica_mix[$acc$net]" > tmp.${flpr}_meica_good.1D
1dcat "$meica_mix[$rej$ves]" > ${flpr}_vessels.1D

# 01.5. Orthogonalise them
1dtranspose ${flpr}_vessels.1D > tmp.${flpr}_meica_rej.1D
3dTproject -ort tmp.${flpr}_meica_good.1D -polort -1 -prefix tmp.${flpr}_tr.1D -input tmp.${flpr}_meica_rej.1D -overwrite
1dtranspose tmp.${flpr}_tr.1D > ${flpr}_vessels_ort.1D

# 01.6. Process rejected, vessels, and networks
1dcat "$meica_mix[$acc]" > tmp.${flpr}_meica_good.1D
1dcat "$meica_mix[$rej$ves$net]" > ${flpr}_networks.1D

# 01.7. Orthogonalise them
1dtranspose ${flpr}_networks.1D > tmp.${flpr}_meica_rej.1D
3dTproject -ort tmp.${flpr}_meica_good.1D -polort -1 -prefix tmp.${flpr}_tr.1D -input tmp.${flpr}_meica_rej.1D -overwrite
1dtranspose tmp.${flpr}_tr.1D > ${flpr}_networks_ort.1D

# 01.8. Preparing lists for fsl_regfilt 
# 01.8.1. Start with dropping the first line of the tsv output.
csvtool -t TAB -u TAB drop 1 ${meica_mix} > tmp.${flpr}_mmix.tsv

# 01.8.2. Add 1 to the indexes to use with fsl_regfilt - which means:
# transpose, add one, transpose, paste different solutions together.
for type in accepted rejected vessels networks
do
	csvtool transpose ${flpr}_${type}_list.1D > tmp.${flpr}_${type}_transpose.1D
	1deval -a tmp.${flpr}_${type}_transpose.1D -expr 'a+1' > tmp.${flpr}_${type}.fsl.1D
	csvtool transpose tmp.${flpr}_${type}.fsl.1D > tmp.${flpr}_${type}.1D
done

cat tmp.${flpr}_rejected.1D > ${flpr}_rejected_fsl_list.1D
paste ${flpr}_rejected_fsl_list.1D tmp.${flpr}_vessels.1D -d , > ${flpr}_vessels_fsl_list.1D
paste ${flpr}_vessels_fsl_list.1D tmp.${flpr}_networks.1D -d , > ${flpr}_networks_fsl_list.1D

# 01.9. Run 4D denoise
# 01.9.1. Transforming kappa based idx into var based idx for each type !!! independently !!!
for type in accepted rejected vessels networks
do
	touch tmp.${flpr}_${type}_var_list.1D
	for i in $( cat tmp.${flpr}_${type}_transpose.1D )
	do
		grep ,${i} < ${meica_fldr}/idx_map.csv | awk -F',' '{print $1}' >> tmp.${flpr}_${type}_var_list.1D
	done
	csvtool -u SPACE transpose tmp.${flpr}_${type}_var_list.1D > ${flpr}_${type}_var_list.1D
done
# 01.9.2. Add a blank line at the beginning probably due to "feature" of 3dSynthesize version Dec 5 2019
echo "   " | cat - ${meica_fldr}/ica_mixing_orig.tsv > tmp.${flpr}_orig_mix

# 02. Running different kinds of denoise: aggressive, orthogonalised, partial regression, multivariate

# 02.1. Running aggressive, orthogonalised, and partial regression
for type in rejected vessels   # networks
do
	3dTproject -input ${func}.nii.gz \
	-ort ${flpr}_${type}.1D  -overwrite \
	-polort -1 -prefix ${fdir}/${bold}_${type}-aggr_bold_bet.nii.gz
	3dTproject -input ${func}.nii.gz \
	-ort ${flpr}_${type}_ort.1D  -overwrite \
	-polort -1 -prefix ${fdir}/${bold}_${type}-orth_bold_bet.nii.gz
	fsl_regfilt -i ${func} \
	-d tmp.${flpr}_mmix.tsv \
	-f "$( cat ${flpr}_${type}_fsl_list.1D )" \
	-o ${fdir}/${bold}_${type}-preg_bold_bet
done

# 02.2. Run 4D denoise (multivariate): recreates a matrix of noise post-ICA, then substract it from original data.
for type in rejected vessels  # networks
do
	3dSynthesize -cbucket ${meica_fldr}/ica_components_orig.nii.gz \
				 -matrix tmp.${flpr}_orig_mix -TR ${TR} \
				 -select $( cat ${flpr}_${type}_var_list.1D ) \
				 -prefix tmp.${flpr}_${type}_volume.nii.gz \
				 -overwrite
done

#### Addon: try reconstructing the good signal only.
3dSynthesize -cbucket ${meica_fldr}/ica_components_orig.nii.gz \
			 -matrix tmp.${flpr}_orig_mix -TR ${TR} \
			 -select $( cat ${flpr}_${type}_var_list.1D ) \
			 -prefix tmp.${flpr}_accepted_volume.nii.gz \
			 -overwrite


# 02.3. Computing voxelwise std of the original volume,
#       multiplying the results of 3dSynthesize to scale them to the original data,
#	    substracting
fslmaths ${func} -Tstd tmp.${flpr}_std
fslmaths ${func} -Tmean tmp.${flpr}_mean

## O: original		A: accepted only	R: rejected only	N: networks only	V: vessels only
## PCA: O = (Y + E) * std(O) + avg(O)						E: noise
## ICA: Y = T*S = A+R+V+N 									T: time decomp		S: space decomp

# Reconstructing "good" data:   (A+V+N)*std(O)+avg(O)
fslmaths tmp.${flpr}_accepted_volume -add tmp.${flpr}_vessels_volume -add tmp.${flpr}_networks_volume \
		 -mul tmp.${flpr}_std -add tmp.${flpr}_mean ${fdir}/${bold}_meica-recn_bold_bet
# Reconstructing "vessel" data:   (A+N)*std(O)+avg(O)
fslmaths tmp.${flpr}_accepted_volume -add tmp.${flpr}_networks_volume \
		 -mul tmp.${flpr}_std -add tmp.${flpr}_mean ${fdir}/${bold}_meica-recn_bold_bet
# # Reconstructing "network" data:   (A)*std(O)+avg(O)
# fslmaths tmp.${flpr}_accepted_volume \
# 		 -mul tmp.${flpr}_std -add tmp.${flpr}_mean ${fdir}/${bold}_meica-recn_bold_bet
# Removing rejected:			[R*std(O)-O]*(-1) = R_0
fslmaths tmp.${flpr}_rejected_volume -mul tmp.${flpr}_std -sub ${func} \
		 -mul -1 ${fdir}/${bold}_meica-mvar_bold_bet
# Removing vessels:			[(R*std(O)-R_0]*(-1) = V_0
fslmaths tmp.${flpr}_vessels_volume -mul tmp.${flpr}_std -sub ${fdir}/${bold}_meica-mvar_bold_bet \
		 -mul -1 ${fdir}/${bold}_vessels-mvar_bold_bet
# # Removing networks:		[R*std(O)-V_0]*(-1)
# fslmaths tmp.${flpr}_networks_volume -mul tmp.${flpr}_std -sub ${fdir}/${bold}_vessels-mvar_bold_bet \
# 		 -mul -1 ${fdir}/${bold}_networks-mvar_bold_bet

rm tmp.${flpr}_*

cd ${cwd}

# 03. Change all the "rejected" names into "meica"
for den in aggr orth preg
do
	immv ${fdir}/${bold}_rejected-${den}_bold_bet ${fdir}/${bold}_meica-${den}_bold_bet
done

# Topup everything!
for type in meica vessels  # networks
do
	for den in recn aggr orth preg mvar
	do
		${cwd}/02.func_preproc/02.func_pepolar.sh ${bold}_${type}-${den}_bold_bet ${fdir} ${sbrf}_topup
		imrm ${bold}_${type}-${den}_bold_bet.nii.gz
		${cwd}/02.func_preproc/09.func_spc.sh ${bold}_${type}-${den}_bold_tpp ${fdir}
		imrm ${bold}_${type}-${den}_bold_mean.nii.gz
		immv ${fdir}/${bold}_${type}-${den}_bold_tpp ${fdir}/00.${bold}_${type}-${den}_bold_native_preprocessed
		immv ${fdir}/${bold}_${type}-${den}_bold_SPC ${fdir}/01.${bold}_${type}-${den}_bold_native_SPC_preprocessed
	done
done
