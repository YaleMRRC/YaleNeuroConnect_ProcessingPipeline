#!/bin/sh
# the next line restarts using wish \
	exec vtk "$0" -- "$@"

#BIOIMAGESUITE_LICENSE  ---------------------------------------------------------------------------------
#BIOIMAGESUITE_LICENSE  This file is part of the BioImage Suite Software Package.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  X. Papademetris, M. Jackowski, N. Rajeevan, H. Okuda, R.T. Constable, and L.H
#BIOIMAGESUITE_LICENSE  Staib. BioImage Suite: An integrated medical image analysis suite, Section
#BIOIMAGESUITE_LICENSE  of Bioimaging Sciences, Dept. of Diagnostic Radiology, Yale School of
#BIOIMAGESUITE_LICENSE  Medicine, http:#www.bioimagesuite.org.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  This program is free software; you can redistribute it and/or
#BIOIMAGESUITE_LICENSE  modify it under the terms of the GNU General Public License version 2
#BIOIMAGESUITE_LICENSE  as published by the Free Software Foundation.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  This program is distributed in the hope that it will be useful,
#BIOIMAGESUITE_LICENSE  but WITHOUT ANY WARRANTY; without even the implied warranty of
#BIOIMAGESUITE_LICENSE  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#BIOIMAGESUITE_LICENSE  GNU General Public License for more details.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  You should have received a copy of the GNU General Public License
#BIOIMAGESUITE_LICENSE  along with this program; if not, write to the Free Software
#BIOIMAGESUITE_LICENSE  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#BIOIMAGESUITE_LICENSE  See also  http:#www.gnu.org/licenses/gpl.html
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  If this software is modified please retain this statement and add a notice
#BIOIMAGESUITE_LICENSE  that it had been modified (and by whom).  
#BIOIMAGESUITE_LICENSE 
#BIOIMAGESUITE_LICENSE  -----------------------------------------------------------------------------------


lappend auto_path [ file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]

package provide bis_fdr 1.0
package require bis_dualimagealgorithm	1.0
package require bis_tmaptopvalue 1.0
package require bis_zscoretopvalue 1.0
package require bis_maskimage 1.0
package require bis_shiftscaleimage 1.0

itcl::class bis_fdr {

    inherit bis_dualimagealgorithm 
    
    constructor { } {	 $this Initialize  }
    
    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Compute FDR" }
    #override parent function
    public method CheckInputObjects { }
    public method UpdateOutputFilenames { }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_fdr::Initialize { } {

    PrintDebug "bis_fdr::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ inptype     "Data type of input" "Input data type" { listofvalues radiobuttons } t { t z p "1-p" }	   0 }
	{ usemask     "Use Mask"	  "Use Mask"   boolean			     0 { 0 1  }	      5 } 
	{ autoscale   "Detect Whether t-values are scaled by 1000 or not"	  "AutoScale"   boolean	 1 { 0 1  }  6 } 
	{ scaleFactor "Scale factor "     "Scale" float  1.0  { -100000000.0 100000000.0 }	-20 }
	{ dof	      "Degree of Freedom" "DOF"	  int	 1    { .0	      100000000	  }  10 }
	{ q	          "FDR bound "	  "q"	  float	 0.01 { 0.0 1.0 } 30 }	       
	{ guiout      "Results from FDR Computation" "Info:"  comment  "         " ""  40 }
    }
	
	
	set defaultsuffix { "_fdr" }
	
	
	set scriptname bis_fdr
	set completionstatus "Done"
	
	#
	#document
	#
	
	set description "Compute False Detection Rate."
	set description2 "An approach to control the expected proportion of false positives. Takes p-values and a FDR rate, and returns a p-value thresholds."
	set backwardcompatibility ""
	set authors "isabella.murphy@yale.edu, xilin.shen@yale.edu."
	
	$this InitializeDualImageAlgorithm
	
	$this RenameInput 0 "Functional Image"
	#set priority to 102 to make it optional
	$this RenameInput 1 "Mask Image" 102
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_fdr::Execute {  } {


    set con 0
    catch {set con [ vtkbisFDR New ]	}
    if { $con == 0 } {
	pxtclvtkpxcontrib::LoadLibraries { vtkpxImagingTCL }
    }
    catch { $con Delete }
    
    PrintDebug "bis_fdr::Execute"
    
    set inptype	    [ $OptionsArray(inptype)	     GetValue  ]
    set dof	        [ $OptionsArray(dof)	  GetValue  ]
    set scaleFactor [ $OptionsArray(scaleFactor)  GetValue  ]
    set q	        [ $OptionsArray(q)		  GetValue  ]
    set image_in    [ $this GetInput ]
    set autoscale   [ $OptionsArray(autoscale)  GetValue  ]
	
    set fdr 0
    catch { set fdr  [ vtkbisFDR New ] }
    if { $fdr == 0 } {
	return 0
    }

    set tmpimg [ pxitclimage \#auto ]
    set textv ""
    
    if { $inptype == "t" } {
	puts stdout "Computing t-to-p conversion"
	set cal [ bis_tmaptopvalue \#auto ]
	$cal InitializeFromContainer $this
	$cal SetInput $image_in 
	$cal SetOptionValue dof $dof
	$cal SetOptionValue autoscale $autoscale
	$cal SetOptionValue scaleFactor $scaleFactor
	$cal Execute
	$this SetOptionValue scaleFactor [ $cal GetOptionValue scaleFactor]
	set textv "(SFactor = [ $cal GetOptionValue scaleFactor ])"

	# GetOutput = pxitclimage
	# [  GetOutput	] GetImage = vtkImageData  (GetImage is same as GetObject )
	$tmpimg ShallowCopy [ $cal GetOutput ] 
	itcl::delete obj $cal
    } elseif { $inptype == "z" } {
	puts stdout "Computing z-to-p conversion"
	set cal [ bis_zscoretopvalue \#auto ]
	$cal InitializeFromContainer $this
	$cal SetInput $image_in 
	$cal Execute
	$tmpimg ShallowCopy [ $cal GetOutput ] 
	itcl::delete obj $cal
    } elseif { $inptype == "1-p" } {
	puts stdout "Computing (1-p)-to-p conversion"
	set cal [ bis_shiftscaleimage \#auto ]
	$cal InitializeFromContainer $this
	$cal SetInput $image_in 
	$cal SetOptionValue shift  -1.0
	$cal SetOptionValue scale -1.0
	$cal SetOptionValue abs	   1
	$cal Execute
	# GetOutput = pxitclimage
	# [  GetOutput	] GetImage = vtkImageData  (GetImage is same as GetObject )
	$tmpimg ShallowCopy [ $cal GetOutput ] 
	itcl::delete obj $cal
    } else {
	#puts stderr "Simple Shallow Copy"
	$tmpimg ShallowCopy $image_in
    }
    
    #$tmpimg Save "/mnt/cluster1/isabella/Desktop/empty fdr/fdrinput.nii.gz"
	#de
set inpname "t-p_result.nii.gz"
#$tmpimg Save $inpname
	#de
    $fdr SetInput [ $tmpimg GetImage ]
    $fdr SetQ $q

    set msk [ $OptionsArray(usemask) GetValue ]
    if { $msk == "1" } {
	puts stdout "Using Mask ..."
	$fdr SetImageMask [ [ $this GetInputObject second_image ] GetObject ]
    } 
    $this SetFilterCallbacks $fdr "Compute FDR"
    $fdr Update

    set textv "Cutoff = [ $fdr GetMaxPvalue ] $textv"
    $OptionsArray(guiout) SetValue $textv
    puts stdout "Output Info=$textv"
	
    set cast [ vtkImageCast New ]
    $cast SetInput [ $fdr GetOutput ]
    $cast SetOutputScalarType [ [ $image_in GetImage ] GetScalarType ]


    set math [ vtkImageMathematics New ]
    $math SetInput1 [ $image_in GetImage ]
    $math SetInput2 [ $cast GetOutput ]
    $math SetOperationToMultiply
    $math Update

    set outimage [ $this GetOutput ]
    $outimage ShallowCopyImage [ $math GetOutput ] 
    $outimage CopyImageHeader  [ $image_in GetImageHeader ]
	
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0
    [ $outimage GetImageHeader ] AddComment "[ $this GetGUIName ] Log: $textv" 0
	
    $fdr Delete
    $cast Delete
    $math Delete
    itcl::delete obj $tmpimg
   
    return 1
}
itcl::body bis_fdr::UpdateOutputFilenames { } {

    set fname ""
    if { $fname == "" } {
	set f(0) [ $InputsArray(input_image) GetFileName ]
	set f(1) [ $InputsArray(second_image) GetFileName ]
	set s(0) [ $OptionsArray(q)		  GetValue  ]
	
	for { set i 0 } { $i <= 1 } { incr i } {
	    set l($i) [ ::bis_common::SplitFileNameGZ $f($i) ]
	    set f($i) [ file tail [ lindex $l($i) 0 ] ]
	    set ext($i) [ lindex $l($i) 1 ]
	}
	set fname [ file join [ file dirname $f(0) ] "$f(0)_$f(1)" ]
    } 
    
    set outlist [ $this CreateDefaultOutputFileList $fname ]
    $OutputsArray(output_image) SetFileName "[ lindex $outlist 0 ]_q$s(0)$ext(0)"
    return 1
}

# -------------------------------------------------------------------------------

itcl::body bis_fdr::CheckInputObjects { } {

    set image_in    [ $this GetInput ]
    set d [ $image_in GetImageSize ]
    if { $d < 2 } {
	return 0
    }
    
    set msk [ $OptionsArray(usemask) GetValue ]
    if { $msk == "1" } {
	set image_in	[ $this GetSecondInput ]
	set d [ $image_in GetImageSize ]
	if { $d < 2 } {
	    return 0
	}
    }
    
    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_fdr.tcl) if it is execute
# ----------------------------------------------------------------------------------------
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function
    set alg [bis_fdr [pxvtable::vnewobj]]
    $alg MainFunction 
}





