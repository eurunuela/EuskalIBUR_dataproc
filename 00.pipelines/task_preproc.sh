#!/usr/bin/env bash

######### Task preproc for EuskalIBUR
# Author:  Stefano Moia
# Version: 1.0
# Date:    25.08.2020
#########


sub=$1
ses=$2
task=$3
wdr=$4

flpr=$5

fdir=$6

vdsc=$7

TEs="$8"
nTE=$9

siot=${10}

dspk=${11}

scriptdir=${12:-/scripts}

tmp=${13:-/tmp}
tmp=${tmp}/${sub}_${ses}_${task}

# This is the absolute sbref. Don't change it.
sbrf=${wdr}/sub-${sub}/ses-${ses}/reg/sub-${sub}_sbref
mask=${sbrf}_brain_mask

### print input
printline=$( basename -- $0 )
echo "${printline} " "$@"
######################################
#########    Task preproc    #########
######################################

# Start making the tmp folder
mkdir ${tmp}

for e in $( seq 1 ${nTE} )
do
	echo "************************************"
	echo "*** Copy ${task} BOLD echo ${e}"
	echo "************************************"
	echo "************************************"

	echo "bold=${flpr}_task-${task}_echo-${e}_bold"
	bold=${flpr}_task-${task}_echo-${e}_bold

	echo "imcp ${wdr}/sub-${sub}/ses-${ses}/func/${bold} ${tmp}/${bold}"
	imcp ${wdr}/sub-${sub}/ses-${ses}/func/${bold} ${tmp}/${bold}

	if [ ! -e ${tmp}/${bold}.nii.gz ]
	then
		echo "Something went wrong with the copy"
		exit
	else
		echo "File copied, start preprocessing"
	fi

	echo "************************************"
	echo "*** Func correct ${task} BOLD echo ${e}"
	echo "************************************"
	echo "************************************"

	${scriptdir}/02.func_preproc/01.func_correct.sh ${bold} ${fdir} ${vdsc} ${dspk} ${siot} ${tmp}
done

echo "************************************"
echo "*** Func spacecomp ${task} echo 1"
echo "************************************"
echo "************************************"

echo "fmat=${flpr}_task-${task}_echo-1_bold"
fmat=${flpr}_task-${task}_echo-1_bold

${scriptdir}/02.func_preproc/03.func_spacecomp.sh ${fmat}_cr ${fdir} none ${sbrf} none none ${tmp}

for e in $( seq 1 ${nTE} )
do
	echo "************************************"
	echo "*** Func realign ${task} BOLD echo ${e}"
	echo "************************************"
	echo "************************************"

	echo "bold=${flpr}_task-${task}_echo-${e}_bold_cr"
	bold=${flpr}_task-${task}_echo-${e}_bold_cr
	${scriptdir}/02.func_preproc/04.func_realign.sh ${bold} ${fmat} ${mask} ${fdir} ${sbrf} none ${tmp}
done

echo "************************************"
echo "*** Func MEICA ${task} BOLD"
echo "************************************"
echo "************************************"

${scriptdir}/02.func_preproc/05.func_meica.sh ${fmat}_bet ${fdir} "${TEs}" none ${tmp} ${scriptdir}

echo "************************************"
echo "*** Func T2smap ${task} BOLD"
echo "************************************"
echo "************************************"
# Since t2smap gives different results from tedana, prefer the former for optcom
${scriptdir}/02.func_preproc/06.func_optcom.sh ${fmat}_bet ${fdir} "${TEs}" ${tmp}

# As it's ${task}, only skip denoising (but create matrix nonetheless)!
for e in $( seq 1 ${nTE}; echo "optcom" )
do
	if [ ${e} != "optcom" ]
	then
		e=echo-${e}
	fi
	echo "bold=${flpr}_task-${task}_${e}_bold"
	bold=${flpr}_task-${task}_${e}_bold
	
	echo "************************************"
	echo "*** Func Nuiscomp ${task} BOLD ${e}"
	echo "************************************"
	echo "************************************"

	${scriptdir}/02.func_preproc/07.func_nuiscomp.sh ${bold}_bet ${fmat} none none ${sbrf} ${fdir} none no 0.3 0.05 5 yes yes yes yes ${tmp}
	
	echo "************************************"
	echo "*** Func Pepolar ${task} BOLD ${e}"
	echo "************************************"
	echo "************************************"

	${scriptdir}/02.func_preproc/02.func_pepolar.sh ${bold}_bet ${fdir} ${sbrf}_topup none none ${tmp}

	echo "************************************"
	echo "*** Func smoothing ${task} BOLD ${e}"
	echo "************************************"
	echo "************************************"

	${scriptdir}/02.func_preproc/08.func_smooth.sh ${bold}_tpp ${fdir} 5 ${mask} ${tmp}
	echo "fslmaths ${tmp}/${bold}_sm -mas ${mask} ${fdir}/00.${bold}_native_preprocessed"
	fslmaths ${tmp}/${bold}_sm -mas ${mask} ${fdir}/00.${bold}_native_preprocessed -odt short

	# echo "************************************"
	# echo "*** Func SPC ${task} BOLD ${e}"
	# echo "************************************"
	# echo "************************************"

	# ${scriptdir}/02.func_preproc/09.func_spc.sh ${bold}_sm ${fdir} ${tmp}

	# # Rename output
	# echo "immv ${tmp}/${bold}_SPC ${fdir}/01.${bold}_native_SPC_preprocessed"
	# immv ${tmp}/${bold}_SPC ${fdir}/01.${bold}_native_SPC_preprocessed

done

echo "rm -rf ${tmp}"
rm -rf ${tmp}