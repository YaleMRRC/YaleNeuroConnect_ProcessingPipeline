#!/bin/tcsh

# Enter the filepath where raw DICOM files are stored
cd /sample/rawdicoms   

# Input filenames here
foreach subj (XXXX_dicom)
  biswebnode dicomconversion -i {$subj} -o /sample/ -b 'true'
end
