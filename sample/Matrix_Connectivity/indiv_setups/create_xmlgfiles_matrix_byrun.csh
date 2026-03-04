#!/bin/tcsh

set subfile='text_files/SubjList.txt'
set subjlist = ( `awk '{print $1}' "$subfile"` )

foreach sub_nr ( `seq 1 1 $#subjlist`)

    set sub = ($subjlist[$sub_nr])
    cp text_files/template_matrix_8runs.xmlg ${sub}_matrix_shen268.xmlg

    # Sort to keep pairing stable with motion files
    set restserlist = ( `ls -1 /sample/sourcedata/${sub}/ses-*/func/R* | sort` )

    # Motion mats live in func/*realign/ and have similar naming; sort for stable pairing
    set restmotionlist = ( `ls -1 /sample/sourcedata/${sub}/ses-01/func/*realign/*hiorder.mat | sort` )

    foreach sernr ( `seq 1 1 $#restserlist` )
        set restrun    = ($restserlist[$sernr])
        set restmotion = ($restmotionlist[$sernr])
        /sample/software/change_replace RESTIMAGE${sernr}  $restrun    ${sub}_matrix_shen268.xmlg
        /sample/software/change_replace RESTMOTION${sernr} $restmotion ${sub}_matrix_shen268.xmlg
    end

    # Anat + registrations now under ses-01/anat
    set mprage = `ls /sample/sourcedata/${sub}/ses-*/anat/*optiBET_brain.nii.gz | tail -1`
    set refreg = `ls /sample/sourcedata/${sub}/ses-*/anat/MNI*${sub}*3rdpass.grd | tail -1`

    # func registrations now under ses-01/func
    set fctreg = `ls /sample/sourcedata/${sub}/ses-*/func/*converted.matr`

    # Robust basename instead of cut -f9 -d/
    set invname = `basename "$refreg"`
    set invrefreg = /sample/sourcedata/${sub}/ses-*/anat/Inverse_${invname}

    /sample/software/change_replace MPRAGEIMAGE        $mprage    ${sub}_*.xmlg
    /sample/software/change_replace INVREFREGISTRATION $invrefreg ${sub}_*.xmlg
    /sample/software/change_replace REFREGISTRATION    $refreg    ${sub}_*.xmlg
    /sample/software/change_replace FCTREGISTRATION    $fctreg    ${sub}_*.xmlg
    /sample/software/change_replace SUBNUMBER          $sub       ${sub}_*.xmlg
end
