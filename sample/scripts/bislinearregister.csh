#!/bin/tcsh

# Change this path to where your bioimage suite lives
source /sample/software/bioimagesuite35/setpaths.csh
setenv FSLOUTPUTTYPE NIFTI_GZ

cd /sample/sourcedata

# Edit subject IDs
foreach subj (sub-XXXX)

	cd ${subj}/func
	
	set epiimage = `ls mean*bold.nii.gz`
	set t1image = `ls ../anat/*optiBET_brain.nii.gz`

echo "epi_reg --epi=$epiimage --t1=$t1image --t1brain=$t1image --out=${subj}_FCTto3Depireg.nii.gz"

	epi_reg --epi=$epiimage --t1=$t1image --t1brain=$t1image --out=${subj}_FCTto3Depireg.nii.gz

echo ${subj}_FCTto3Depireg.nii.gz
echo $epiimage
echo ${subj}_FCTto3Depireg_converted.matr

echo	"bis_linearintensityregister.tcl -inp ${subj}_FCTto3Depireg.nii.gz -inp2 $epiimage -out ${subj}_FCTto3Depireg_converted.matr"

	bis_linearintensityregister.tcl -inp ${subj}_FCTto3Depireg.nii.gz -inp2 $epiimage -out ${subj}_FCTto3Depireg_converted.matr

	cd ../..
end
