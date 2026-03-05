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
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] main]

package require bis_algorithm 1.0
package require bis_newreorientimage 1.0

package provide bis_dicom2nifti 1.0

#
# Operations involving multisubject average for testing ....
#

itcl::class bis_dicom2nifti {

    inherit bis_algorithm
    
    constructor { } {
	$this Initialize
    }

    public method Initialize { }
    public method Execute { }
    public method PrintOutput { nn }
    public method GetGUIName { } { return "DICOM 2 NIFTI" }
}
# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_dicom2nifti::Initialize { } {

    PrintDebug "bis_dicom2nifti::Initialize" 

    #name,description,type,object,filename(if applicable),priority (optional)
    set inputs { }
    set outputs { }

    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ indir "Input directory containing DICOM Files" "Input Directory:"  { filename directory 40 }  "" "" 1 }
	{ outdir "Output directory for NIFTI Files" "Output Directory:"  { filename directory 40 }  "" "" 2 }
	{ mode "Postprocessing of Original Data" "Mode"  listofvalues  NONE { NONE RAS LPS }   3}
	{ name  "Study Name" "Name"  { string 20 }  "" ""  4 }
	{ dosave "If set to off no files are created" "Do Save:"  { boolean checkbutton } 1 { 0 1 }  -10 }
	{ dodump "If set to one (default) then a dump of one of the dicom files in a series is saved" "Do DICOM Dump:"  { boolean checkbutton } 1 { 0 1 }  -4 }
	{ debugmode "Extra Header Info (if dodump=1)" "DebugMode"  listofvalues  NONE { NONE SIEMENS GE }   -20 }

    }

    set outputs { }

    set defaultsuffix { "" }

    set scriptname bis_dicom2nifti
    set completionstatus ""
    #
    #document
    #
    set category "Utility"
    set description "This script parses a directory containing DICOM images and creates NIFTI output files"
    set description2 "Has capabilities for Siemens Mosaic Format (for FMRI)"
    set backwardcompatibility "Based on original ImageConversion script at Yale MRRC"
    set authors "xenophon.papademetris.yale.edu"

    $this AddDefaultOptions


}

itcl::body bis_dicom2nifti::PrintOutput { nn } {

    if { $basewidget == 0 } {
	puts stdout "${nn}"
    } else {
	pxtkprint "${nn}\n"
    }
}


itcl::body bis_dicom2nifti::Execute {  } {

    set dryrun 0
    if { [ $OptionsArray(dosave) GetValue ] == 0 } {
	set dryrun 1
    }
    
    set basedir [ file normalize [ $OptionsArray(indir) GetValue ] ]

    set savednames ""

    set outputdir [ $OptionsArray(outdir) GetValue ] 

    if { $outputdir == "" } {
	set n [ pid ]
	set f  [ file join [ pwd ] nifti_$n ]
	while { [ file exists $f ] > 0 } {
	    incr n
	    set f  [ file join $outdir tmp_$n ]
	}
	set outputdir $f 
    }

    set outputdir [ file normalize $outputdir ]
    catch {    file mkdir $outputdir }


    set dodump [ $OptionsArray(dodump) GetValue ]
    set debugmode [ $OptionsArray(debugmode) GetValue ]
    set outmode [ $OptionsArray(mode) GetValue ]
    set pname   [ $OptionsArray(name) GetValue ]


    if { $basewidget != 0 } {
	pxtkconsole
    }

    $this PrintOutput "Beginning -- Input Directory = $basedir, outputdir=$outputdir, convmode=$outmode, pname=$pname"
    
    set dname $basedir
    cd $dname
    

    # ----------------------------------------------------------------------
    # Find last acquired image, newest file in $dname
    # ----------------------------------------------------------------------
    
    set outname "$basedir"
    set convertedlist ""
    set done 0
    set pass 0
    while { $done == 0 } {
	
	incr pass
	set a [ glob [ file join $dname * ] ]
	set lst ""
	for { set i 0 } { $i < [ llength $a ] } { incr i } {
	    set f [ lindex $a $i ]
	    set f2 [ file tail $f ]
	    set ind [ lsearch -exact $convertedlist $f2 ] 
	    #	$this PrintOutput "Searching for $f2 in [ lindex $convertedlist 0 ], index = $ind"
	    if { $ind == -1 } {
		lappend lst $f
	    }
	}
	
	if { [ llength $lst ] == 0 } {
	    $this PrintOutput "\n\n------------------------------------------------------------\n No More Files To Convert \n------------------------------------------------------------\n"

	    set savednames [ lsort -ascii -index 0 $savednames  ]
	    for { set i 0 } { $i < [ llength $savednames ] } { incr i } {
		$this PrintOutput "[ expr $i +1 ]. [ lindex [ lindex $savednames $i ] 0 ]  ( [ lindex [ lindex $savednames $i ] 1 ] )"
	    }
	    return 1
	}
	
	$this PrintOutput "\n\n------------------------------------------------------------\n Doing Pass $pass \n------------------------------------------------------------\n"
	$this PrintOutput "Number of Available DICOM Images to process = [ llength $lst ]"
	
	
	set anchorfile [ lindex $lst 0 ]
	$this PrintOutput "First file = [ file join $dname $anchorfile ]"
	
	# ----------------------------------------------------------------------
	#  Read $anchorfile file and extract key info (e.g. patientid)
	# ----------------------------------------------------------------------
	


	set dcm [ vtkbisDICOMReader New ]
	$dcm SetFileName $anchorfile
	$dcm Update

	puts stdout "$anchorfile done"
	
	set pid [ $dcm GetPatientID ]
	if { [ string length $pname ] < 2 } {
	    set pname [ $dcm GetPName ]
	}
	if { [ string length $pname ] < 2 } {
	    set pname "Study"
	}
	set pst [ $dcm GetStudy]
	set pse [ $dcm GetSeries ]
	set pdt [ $dcm GetDate ]
	if { $pse == "" } {
	    set pse 0
	}
	$dcm Delete
	
	if { $pst != "1" } {
	    set outname2 [ format "%s_s%03d_s_%s_%s" $pid $pse $pst $pname $pdt  ]
	} else {
	    set outname2 [ format "%s_s%03d_%s_%s" $pid $pse $pname $pdt  ]
	}
	regsub -all " +" $outname2 "" outname2
	set outname [ file join $outputdir $outname2 ]
	$this PrintOutput "NIFTI Output name stem =$outname"
	
	
	
	# ----------------------------------------------------------------------
	#  Do Full Blown DICOM Import
	# ----------------------------------------------------------------------
	
	set img [ [ pxitclimage \#auto ] GetThisPointer ]
	set pxitclimage::forcebioimagesuitecoordinates 0
	puts stdout "$img LoadDICOM $anchorfile 0 0"
	$img LoadDICOM $anchorfile 0 0
	
	$this PrintOutput "Reading Input Image Done\n"
	
	set lst [ $img cget -lastdicomlist ]
	for { set i 0 } { $i < [ llength $lst ] } { incr i } {
	    set nf [ file tail [ lindex [ lindex $lst $i ] 0 ] ]
	    lappend convertedlist $nf
	}
	$this PrintOutput "Adding [ llength $lst ] files to list of images already converted"
	
	$img configure  -lastdicomlist ""
	
	set nf [ [ $img GetImage ] GetNumberOfScalarComponents ]
	set extra "stack3d" 
	if { $nf > 1 } {
	    set extra "stack4d"
	}

	if { $dryrun == 0 && $dodump > 0} {
	    set txtname "${outname}_${extra}_orig_header.txt"
	    set eflag "-V"
	    if { $debugmode == "SIEMENS" } {
		set eflag "--csa" 
	    } elseif { $debugmode == "GE" } {
		set eflag "--pdb"
	    }
	    
	    $this PrintOutput "Executing gdcmdump -i $anchorfile $eflag -p "
	    catch { file delete $txtname }
	    catch { exec gdcmdump -i $anchorfile $eflag -p > $txtname  }
	    if { [ file exists $txtname ] } {
		$this PrintOutput "\t\t DICOM Dump saved in $txtname"
	    } else {
		$this PrintOutput "\t\t DICOM Dump failed"
	    }
	}

	if { $outmode == "NONE" } {
	    set f1 ${outname}_${extra}_orig.nii.gz 
	    set dm [ [ $img GetImage ] GetDimensions ]
	    set details "d=$dm, $nf"
	    if { $dryrun == 0 } {
		$img Save $f1
		$this PrintOutput "Output NIFTI image saved in $f1 ($details), file size=[ file size $f1 ]"
	    } else {
		$this PrintOutput "Output should have been saved in $f1 ($details)"
	    }
	    lappend savednames [ list $f1 $details ]

	} else {
	    set dm [ [ $img GetImage ] GetDimensions ]

	    set reorient [ bis_newreorientimage \#auto ]
	    $reorient InitializeFromContainer 0
	    $reorient SetInput $img
	    $reorient SetOptionValue orientation $outmode
	    $reorient Execute
	    
	    set finalimg [ [ pxitclimage \#auto ] GetThisPointer ]
	    $finalimg ShallowCopy [ $reorient GetOutput ]
	    itcl::delete object $reorient
	    
	    set dm2 [ [ $finalimg GetImage ] GetDimensions ]

	    set f2 ${outname}_${extra}_${outmode}.nii.gz
	    set details "d=$dm -- >$dm2, $nf" 
	    if { $dryrun == 0 } {
		$finalimg  Save $f2
		$this PrintOutput "Reoriented ($outmode) output NIFTI image saved in $f2 ($details), file size=[ file size $f2 ]"
	    } else {
		$this PrintOutput "Reoriented ($outmode) output should have been saved in $f2 ($details)"
	    }
	    lappend savednames [ list $f2 $details ]
	    itcl::delete obj $finalimg 
	}
	itcl::delete object $img
    }
}
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_dicom2nifti [pxvtable::vnewobj]]
    $alg MainFunction 
}

