#!/usr/bin/env bash

######### FUNCTIONAL 03 for PJMASK
# Author:  Stefano Moia
# Version: 0.1
# Date:    06.02.2019
#########

## Variables
# functional
func=$1
# folders
fdir=$2
# echo times
TEs=$3
######################################
######### Script starts here #########
######################################

cwd=$(pwd)

cd ${fdir}

## 01. MEICA
# 01.1. concat in space

eprfx=${func%_echo-*}_echo-
esffx=${func#*_echo-?}

echo "Merging ${func} for MEICA"
fslmerge -z ${func}_concat $( ls ${eprfx}* | grep ${esffx}.nii.gz )

${cwd}/meica.libs/tedana.py -d ${func}_concat.nii.gz -e ${TEs} --fout --denoiseTEs --label=${func}_meica

# 01.2. Ortogonalising good and bad components

echo "Ortogonalising good and bad components in ${func}"
cd ${func}_meica

nacc=$( cat accepted.txt )
nrej=$( cat rejected.txt )
nmid=$( cat midk_rejected.txt )
allr=${nrej},${nmid}

1dcat meica_mix.1D"[$nacc]" > meica_good.1D
1dcat meica_mix.1D"[$allr]" > meica_rej.1D

3dTproject -ort meica_good.1D -polort -1 -prefix tmp.tr.1D -input meica_rej.1D -overwrite
1dtranspose tmp.tr.1D > rej_ort.1D

cd ${cwd}