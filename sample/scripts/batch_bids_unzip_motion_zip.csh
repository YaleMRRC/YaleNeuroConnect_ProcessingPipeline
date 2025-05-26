#!/bin/tcsh

# Modify this path name to point to where your bioimage suite lives
source /software/bioimagesuite35/setpaths.csh

cd /sample/sourcedata

# Update subject IDs to loop through
foreach subj (sub-XXXX)

cd $subj/func

cp /source/scripts/batch_bids_motionSPM12_XXXX.csh .

echo unzipping $subj
gunzip *task-1trmb5ipat2*bold.nii.gz

echo running motion correction $subj

set motionbatch = `ls *batch*XXXX.csh`

sh ./{$motionbatch}

echo zipping $subj
gzip *.nii

cd ../..

end
