cd /sample/sourcedata

# Input correct subject identifiers here
foreach subj (sub-XXXX)

    # Loop through all session folders (ses-01, ses-02, etc.)
    foreach sesdir ( ${subj}/ses-* )

        cd ${sesdir}/anat

        foreach j ( *T1w.nii.gz )

            # Modify this line to point to where your optiBET.sh (FSL) lives
            /data1/software/optiBET.sh -i $j

        end

        cd ../..

    end

end
