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

package require bis_dualimagealgorithm 1.0
package require bis_resliceimage 1.0
package provide bis_imagecompare 1.0

#
# blend image
#

itcl::class bis_imagecompare {

    inherit bis_dualimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Compute Image Comparison"}

    protected method PackOptionsGUIInterface { lst }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_imagecompare::Initialize { } {

    PrintDebug "bis_imagecompare::Initialize" 

    set inputs { 
	{ first_sigma   "Standard Deviation 1" pxitclimage  ""  102 }   
	{ second_sigma   "Standard Deviation 2" pxitclimage  "" 103 }   
    }


    set options {
	{ n1  "Number of Samples for data set 1 (Mean 1, and Sigma 1)" "N1"   integer   2 { 1 20000 }  0 }
	{ n2  "Number of Samples for data set 2 (Mean 2, and Sigma 2)" "N2"   integer   1 { 1 20000 }  1 }
	{ scale  "Scale Factor to multiply resulting t by (typically 1000)" "Scale"   integer   1000 { 1 1000 }  2 }
    }
	
    set defaultsuffix { "_ttest" }
    
    set scriptname bis_imagecompare
    set completionstatus "Done"
    #
    #document
    #

    set category "Image Processing Dual"
    set description "Add, Subtract, Multiply or Divide two images to give an output. NormalT and PairedT assumed 4D Images and perform t-test comparisons"
    set description2 ""
    set backwardcompatibility " "
    set authors "alark.joshi@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeDualImageAlgorithm
    
    $this RenameInput 0 "Mean Image 1"
    $this RenameInput 1 "Mean Image 2"
}

# -----------------------------------------------------------------------------------------
itcl::body bis_imagecompare::PackOptionsGUIInterface { lst } { 

    
    grid  [ $OptionsArray(n1) GetBaseWidget ] -row 0 -column 0 -padx 0
    grid  [ $OptionsArray(n2) GetBaseWidget ] -row 0 -column 1 -padx 0
    grid  [ $OptionsArray(scale) GetBaseWidget ] -row 0 -column 2 -padx 0

    set v  [ file rootname  [ $OptionsArray(scale) GetBaseWidget ] ]
    grid rowconfigure $v 2 -weight 100
    grid columnconfigure $v 3 -weight 100

    update idletasks
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------
itcl::body bis_imagecompare::Execute {  } {

    PrintDebug "bis_imagecompare::Execute"

    set img1 [ [ $this GetInput ] GetImage ]
    set img2 [ [ $this GetSecondInput ]  GetImage ]
    set sig1 [ [ $this GetInputObject first_sigma ] GetImage ]
    set sig2 [ [ $this GetInputObject second_sigma ] GetImage ]

    set l [ list $img1 $img2 $sig1 $sig2 ]
    for { set i 0 } { $i < [ llength $l ] } { incr i } {
	puts stderr "Dimensions = [ [ lindex $l $i ] GetDimensions ]"
    }


    if { [ $img1 GetNumberOfPoints ] != [ $img2 GetNumberOfPoints ] } {
	set errormessage  "Unequal Image Sizes\n Cannot Perform Compare t-test!"
	return 0
    }

	
    set outimage [ $this GetOutput ] 

    set math [ vtkpxComputeTmap [ pxvtable::vnewobj ]]
    $math SetInput  $img1
    $math SetInput2 $img2
    $math SetInputStandardDeviation  $sig1
    $math SetInputStandardDeviation2 $sig2
    $math SetNumberOfSamples1 [ $OptionsArray(n1) GetValue ] 
    $math SetNumberOfSamples2 [ $OptionsArray(n2) GetValue ] 
    $math SetScaleFactor [ $OptionsArray(scale) GetValue ] 
    $math Update
    $outimage ShallowCopyImage [ $math GetOutput ]
    puts stderr " Results Range: [ [ [ [ $outimage GetImage ] GetPointData ] GetScalars ] GetRange ]"

    set pimage   [ $this GetSecondInput ] 

    $outimage CopyImageHeader [ $pimage GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $math Delete

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_imagecompare.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function
 

    set alg [bis_imagecompare [pxvtable::vnewobj]]
    $alg MainFunction 
}

