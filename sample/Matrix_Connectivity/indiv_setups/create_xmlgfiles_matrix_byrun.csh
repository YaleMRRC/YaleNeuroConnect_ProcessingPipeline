#!/bin/tcsh

set subfile='text_files/SubjList.txt'
set subjlist = ( `awk '{print $1}' "$subfile"` )

foreach sub_nr ( `seq 1 1 $#subjlist`)

	set sub = ($subjlist[$sub_nr])
	cp text_files/template_matrix_8runs.xmlg {$sub}_matrix_shen268.xmlg
	set restserlist=`ls /sample/sourcedata/{$sub}/func/R*`
	set restmotionlist=`ls /sample/sourcedata/{$sub}/func/*realign/*hiorder.mat`

	foreach sernr ( `seq 1 1 $#restserlist` )
		set restrun=($restserlist[$sernr])
		set restmotion=($restmotionlist[$sernr])
		/home/cheryl/change_replace RESTIMAGE${sernr} $restrun {$sub}_matrix_shen268.xmlg
		/home/cheryl/change_replace RESTMOTION${sernr} $restmotion {$sub}_matrix_shen268.xmlg
	end

	set mprage = `ls /sample/sourcedata/{$sub}/anat/*optiBET_brain.nii.gz | tail -1`
	set refreg = `ls /sample/sourcedata/{$sub}/anat/MNI*{$sub}*3rdpass.grd | tail -1`
	set fctreg = `ls /sample/sourcedata/{$sub}/func/*converted.matr`

	set invname=`ls /sample/sourcedata/{$sub}/anat/MNI*{$sub}*3rdpass.grd | tail -1 | cut -f9 -d/`
	set invrefreg=/sample/sourcedata/{$sub}/anat/Inverse_{$invname}

	/home/cheryl/change_replace MPRAGEIMAGE $mprage {$sub}_*.xmlg
	/home/cheryl/change_replace INVREFREGISTRATION $invrefreg  {$sub}_*.xmlg
	/home/cheryl/change_replace REFREGISTRATION $refreg  {$sub}_*.xmlg
	/home/cheryl/change_replace FCTREGISTRATION $fctreg  {$sub}_*.xmlg
	/home/cheryl/change_replace SUBNUMBER $sub {$sub}_*.xmlg
end
