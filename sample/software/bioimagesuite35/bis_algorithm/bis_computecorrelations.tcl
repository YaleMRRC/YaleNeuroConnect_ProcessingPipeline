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

package provide bis_computecorrelations 1.0
package require bis_imagetoimagealgorithm 
package require bis_seedcorrelation

itcl::class bis_computecorrelations {

    inherit bis_imagetoimagealgorithm

    constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Compute Correlations" }


    protected method TextFileToImage { textfile } 
    public method UpdateOutputFilenames { } 
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_computecorrelations::Initialize { } {

    PrintDebug "bis_computecorrelations::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ mname  "specify the measures file used to compute the correlations" "Measures File"   { filename default } "" { text { .txt } }   10 }
	{ split  "save individual measures to separate files (if guimode then off by default)"  "Save Individuals" boolean 0 { 0 1 } 11 }
	{ raw  "Output is raw-correlations instead of z-scores"  "Raw Correlations" boolean 0 { 0 1 } 11 }
    }
	
    set defaultsuffix { "" }
    set category "Functional Imaging"    
    set scriptname bis_computecorrelations
    set completionstatus "Done"
    
    #
    #document
    #
    
    set description "Compute Correlations between the 4D image as input 1 and the measures in filename. 4D Image must have the same number of frames as the subjects in the filename and the frames MUST be in the same order as the subjects as listed below, i.e. The first subject must be in frame 1, the second in frame 2 etc."
    set description2 "Measures File Example\n------------------------"
    append description2 "\n\\\#Individual Subject Measures"
    append description2 "\n\\\#Number of Subjects\n4"
    append description2 "\n\\\#Number of Measures\n2"
    append description2 "\n\\\#Data (either , or tab-delimited)"
    append description2 "\nSubject IQ Weight"
    append description2 "\n1314	100 100"
    append description2 "\n1361	110 200"
    append description2 "\n1518	120 200"
    append description2 "\n2205	130 121"
    append description2 "\n------------------------\n"

    set backwardcompatibility ""
    set authors "isabella.murphy@yale.edu, xenophon.papademetris@yale.edu."
    
    $this InitializeImageToImageAlgorithm
    $this RenameInput 0 "4D Input Image"
}

# -----------------------------------------------------------------------------------------
# FileaNames
# ----------------------------------------------------------------------------------------
itcl::body bis_computecorrelations::UpdateOutputFilenames { } {

    set fname   [ $OptionsArray(mname) GetValue ]
    set l [ ::bis_common::SplitFileNameGZ $fname ]
    set defaultsuffix [ file tail [ lindex $l 0 ] ]
    set ok [ ::bis_imagetoimagealgorithm::UpdateOutputFilenames  ]
    return $ok
}

# -----------------------------------------------------------------------------------------
itcl::body bis_computecorrelations::TextFileToImage { textfile } {

    set fileid [open $textfile r]
	
    gets $fileid line
    set line [ string trim $line ]
    
    if { [ string compare $line "#Individual Subject Measures" ] != 0 } {
	set errormessage  "Bad Measures File File, does not have proper header\n"
	close $fileid
	return 0
    }
    
    set numsubjects 1
    set nummeasures 1
    gets $fileid line;     gets $fileid numsubjects
    gets $fileid line;     gets $fileid nummeasures
    
    puts stdout "Reading textfile = $textfile, numsubjects=$numsubjects, nummeasures=$nummeasures"

    gets $fileid line

    set img [ vtkImageData New ]
    $img SetDimensions $nummeasures 1 1
    $img SetNumberOfScalarComponents $numsubjects
    $img SetScalarTypeToFloat
    $img AllocateScalars
    
    set numcols [ expr $nummeasures +1 ]
    gets $fileid line

    set subjectlist ""
    set measurelist ""

    set ln [ string trim $line ]
    regsub -all " +" $ln "\t" ln
    regsub -all "\t" $ln "|" ln
    regsub -all ","  $ln "|" ln
    set tmp  [ split $ln | ]	
    if { [ llength $tmp ] != $numcols } {
	set errormessage "Not Engough Measure names specified (numcols=$numcols) ($ln,$tmp)"
	close $fileid
	return 0
    }
    for { set i 1 } { $i < $numcols } { incr i } {
	lappend measurelist [ lindex $tmp $i ]
    }


    for { set i 0 } { $i < $numsubjects } { incr i } {
	gets $fileid line
	set ln [ string trim $line ]
	regsub -all " +" $ln "\t" ln
	regsub -all "\t" $ln "|" ln
	regsub -all ","  $ln "|" ln
	set tmp  [ split $ln | ]	
	#	puts stdout "ln=$ln, tmp=$tmp"
	if { [ llength $tmp ] != $numcols } {
	    set errormessage "Bad Line for subject [ expr $i +1 ], number of columns = [ llength $tmp ] != $numcols "
	    close $fileid
	    return 0
	}
	for { set j 1 } { $j < $numcols } { incr j } {
	    $img SetScalarComponentFromDouble [ expr $j -1 ] 0 0 $i [ expr double([ lindex $tmp $j ]) ]
	}
	lappend subjectlist [ lindex $tmp 0 ]
    }
    close $fileid

    puts stdout "Verifying ...."

    puts -nonewline stdout " \t :"
    for { set j 0 } { $j < $nummeasures } { incr j } {
	puts -nonewline stdout " [ lindex $measurelist $j ]\t"
    }
    puts stdout ""

    for { set i 0 } { $i < $numsubjects } { incr i } {
	puts -nonewline stdout "Subject [ lindex $subjectlist $i ] \t"
	for { set j 0 } { $j < $nummeasures } { incr j } {
	    puts -nonewline stdout "[ $img GetScalarComponentAsDouble $j 0 0 $i ]\t"
	}
	puts stdout ""
    }


    set ref [ pxitclimage \#auto ]
    $ref ShallowCopyImage $img
    $ref configure -filename "(from $textfile)"
    $img Delete
    return [ list [ $ref GetThisPointer ] $measurelist ]
}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------
itcl::body bis_computecorrelations::Execute {  } {

    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL vtkbisROICorrelation 0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }

    set raw [ $OptionsArray(raw) GetValue ]

    set mname [ $OptionsArray(mname) GetValue ]
    #    puts stderr "mname=$mname"
    set saveall [ $OptionsArray(split) GetValue ]
    set rlist [ TextFileToImage $mname ]
    if { $rlist == 0 } {
	return 0
    }

    set ref [ $this GetInput ]	
    set roimean     [ lindex $rlist 0 ]
    set measurelist [ lindex $rlist 1 ]


    set corr [ bis_seedcorrelation \#auto ]
    $corr InitializeFromContainer 0
    $corr SetInput $ref
    $corr SetSecondInput $roimean
    $corr SetOptionValue raw $raw
    $corr SetOptionValue ztransform 0
    $corr SetOptionValue usemask 0
    $corr Execute


    if { $saveall > 0 } {
	$this UpdateOutputFilenames
	set outimage [ $corr GetOutput ]
	set tname [ $OutputsArray(output_image) GetFileName]
	set l [ ::bis_common::SplitFileNameGZ $tname ]
	set outname [ lindex $l 0 ]
	set tmp [ pxitclimage \#auto ]

	for { set i 0 } { $i < [ [ $outimage GetImage ] GetNumberOfScalarComponents ] } { incr i } {
	    
	    set extr [ vtkImageExtractComponents New ]
	    $extr SetInput [ $outimage GetImage ]
	    $extr SetComponents $i
	    $extr Update
	    
	    $tmp ShallowCopyImage [ $extr GetOutput ]
	    $tmp CopyImageHeader  [ $outimage GetImageHeader ]
	    set name "${outname}_[ lindex $measurelist $i ].nii.gz"
	    set ok [ $tmp Save $name ]
	    if { $ok > 0 } {
		puts stdout "\t\t Correlation with [ lindex $measurelist $i ] saved in $name"
	    }
	    $extr Delete
	}
	itcl::delete object $tmp
    }

    set output [ $this GetOutput ] 
    $output ShallowCopy [ $corr GetOutput ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $output GetImageHeader ] AddComment "$comment $Log" 0

    set framenames "---------------------------------------------\n"
    append framenames "Frame \t Name\n"
    append framenames "---------------------------------------------\n"
    for { set i 0 } { $i < [ llength $measurelist ] } { incr i } {
	append framenames "[ expr $i+1] \t [ lindex $measurelist $i ]\n"
    }
    append framenames "---------------------------------------------\n"
    [ $output GetImageHeader ] AddComment "[ $this GetGUIName ], framenames\n$framenames" 0

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_mediantemporalsmoothimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_computecorrelations [ pxvtable::vnewobj ] ]
    $alg MainFunction 
}








