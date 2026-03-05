#!/bin/tcsh

source /sample/software/bioimagesuite35/setpaths.csh

set subfile='SubjList.txt'
set subjlist = ( `awk '{print $1}' "$subfile"` )

foreach subnr ( `seq 1 1 $#subjlist`)

    set subj = ($subjlist[$subnr])

    # Loop over all sessions (ses-01, ses-02, ...)
    foreach sesdir ( /sample/sourcedata/${subj}/ses-*/func )
        if ( ! -d "$sesdir" ) continue

        cd "$sesdir"

        foreach j ( R*.nii.gz )
            3dBlurToFWHM -temper -automask -FWHM 6 -input "$j" -prefix "$j:s/.nii.gz/_unism.nii.gz/"
        end
    end
end
