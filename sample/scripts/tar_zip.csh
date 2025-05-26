#!/bin/tcsh

# Change to the path where your raw DICOMS are stored
cd /sample/rawdicoms

# Modify filenames as needed
foreach subj (XXXX_dicom)
	tar -cvzf {$subj}.tgz {$subj}
end

