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

package require bis_imagetoimagealgorithm 1.0

package provide bis_cropimage 1.0

#
# smooth image
#

itcl::class bis_cropimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Crop Image" }

    # Override these methods
    protected method PackOptionsGUIInterface { lst }
    public method UpdateInputsFromContainer { }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_cropimage::Initialize { } {

    PrintDebug "bis_cropimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ startx   "Start Value of Crop Region in X" "Start X"  { integer default   } 0 { -100 1999 }  0 }
	{ stopx    "End  Value of Crop Region in X" "Stop X"    { integer default   } -1 { -100 1999 }  1 }
	{ ratex    "X Increment for Cropping" "Rate X"          { integer default 2 } 1 { 1    50 }  2 }
	{ starty   "Start Value of Crop Region in Y" "Start Y"  { integer default   } 0 { -100 1999 }  3 }
	{ stopy    "End  Value of Crop Region in Y" "Stop Y"    { integer default   } -1 { -100 1999 }  4 }
	{ ratey    "Y Increment for Cropping" "Rate Y"          { integer default 2 } 1 { 1    50 }  5 }
	{ startz   "Start Value of Crop Region in Z" "Start Z"  { integer default   } 0 { -100 1999 }  6 }
	{ stopz    "End  Value of Crop Region in Z" "Stop Z"    { integer default   } -1 { -100 1999 }  7 }
	{ ratez    "Z Increment for Cropping" "Rate Z"          { integer default 2 } 1 { 1    50 }  8 }
	{ startt   "Start Value of Crop Region in T" "Start T"  { integer default   } 1 { 1   999 }  9 }
	{ stopt    "End  Value of Crop Region in T" "Stop T"    { integer default   } 999 { 1   999 } 10 }
	{ ratet    "T Increment for Cropping" "Rate T"          { integer default 2 } 1 { 1    50 } 11 }

	{ blank    "If set to on perform blank instead of crop" "Blank" { listofvalues radiobuttons }  off { on off }   12 }
	{ autocrop "If set to on perform autocrop instead of crop" "AutoCrop" { listofvalues radiobuttons }  off { on off }   13 }
	{ autocroppad  "Padding Value Used for AutoCropping factor of the gaussian in voxel units " "Autocrop Boundary Size" integer  2   { 0 10 }  -1 }
    }

    set defaultsuffix { "_crop" }
    
    set scriptname bis_cropimage
    set completionstatus "Done"
    #
    #document
    
    set description "Crops an image with a specific cropping window/radius."
    set description2 "Optionally can be used to blank image or autocrop."
    set backwardcompatibility "Reimplemented from GUI code in pxitclimageutility.tcl.  "
    set authors "xenophon.papademetris@yale.edu."

    $this InitializeImageToImageAlgorithm

}

itcl::body bis_cropimage::UpdateInputsFromContainer { } {

    bis_imagetoimagealgorithm::UpdateInputsFromContainer 

    # This happens when image has changed 
    set currentimage  [ $InputsArray(input_image) GetObject ]


    scan [ [ $currentimage GetImage ] GetDimensions ] "%d %d %d" dim(0) dim(1) dim(2)
    for { set i 0 } { $i <=2 } { incr i } { 
	set dim($i) [ expr $dim($i) -1 ] 
	set min($i) -100
	set max($i) [ expr $dim($i) + 100 ]
    }

    set nc [ [ $currentimage GetImage ] GetNumberOfScalarComponents ]


    $OptionsArray(startx) SetValueRange [ list $min(0) $dim(0)  ]
    $OptionsArray(stopx)  SetValueRange [ list 0 $max(0) ]
    $OptionsArray(starty) SetValueRange [ list $min(1) $dim(1) ]
    $OptionsArray(stopy)  SetValueRange [ list 0 $max(1) ]
    $OptionsArray(startz) SetValueRange [ list $min(2)  $dim(2) ]
    $OptionsArray(stopz)  SetValueRange [ list  0 $max(2) ]
    $OptionsArray(startt) SetValueRange [ list 1 $nc ]
    $OptionsArray(stopt)  SetValueRange [ list 1 $nc ]

    if { $guimode == "managed" || $guimode =="standalone" } {
	$OptionsArray(startx) SetValue 0
	$OptionsArray(stopx)  SetValue  $dim(0) 
	$OptionsArray(starty) SetValue 0
	$OptionsArray(stopy)  SetValue $dim(1) 
	$OptionsArray(startz) SetValue 0
	$OptionsArray(stopz)  SetValue $dim(2) 
	$OptionsArray(startt) SetValue 1
	$OptionsArray(stopt)  SetValue $nc
    } else {
	$OptionsArray(startx) SetValueIfCurrentIsTheDefault 0
	$OptionsArray(stopx)  SetValueIfCurrentIsTheDefault  $dim(0) 
	$OptionsArray(starty) SetValueIfCurrentIsTheDefault 0
	$OptionsArray(stopy)  SetValueIfCurrentIsTheDefault  $dim(1) 
	$OptionsArray(startz) SetValueIfCurrentIsTheDefault 0
	$OptionsArray(stopz)  SetValueIfCurrentIsTheDefault  $dim(2) 
	$OptionsArray(startt) SetValueIfCurrentIsTheDefault 1
	$OptionsArray(stopt)  SetValueIfCurrentIsTheDefault $nc
    }
}


itcl::body bis_cropimage::PackOptionsGUIInterface { lst } { 


    set n [ llength $lst ]
    PrintDebug "\n\n Length of list = $n"

    for { set tab 0 } { $tab <= 1 } { incr tab } {
	set wlist ""
	for { set i 0 } { $i < $n } { incr i } {
	    
		set pair [ lindex $lst $i ]
		set ind  [ lindex $pair 1 ]
		if { $ind == $tab } {
		    lappend wlist $pair
		}
	    }

	set wlist [ lsort -integer  -index 0 $wlist ]


	if { $tab == 1 } {
	    for { set j 0 } { $j < [ llength $wlist ] } { incr j } {
		set pair [ lindex $wlist $j ]
		set name [ lindex $pair 2 ]
		set widg [ lindex $pair 3 ]
		pack $widg -side top -expand false -fill x -padx 1
	    }
	} else {
	    # Custom Pack
	    grid  [ $OptionsArray(startx) GetBaseWidget ] -row 0 -column 0 -padx 0 
	    grid  [ $OptionsArray(stopx) GetBaseWidget ]  -row 0 -column 1 -padx 0 
	    grid  [ $OptionsArray(ratex) GetBaseWidget ]  -row 0 -column 2 -padx 0 

	    grid  [ $OptionsArray(starty) GetBaseWidget ]  -row 1 -column 0 -padx 0 
	    grid  [ $OptionsArray(stopy) GetBaseWidget ]   -row 1 -column 1 -padx 0
	    grid  [ $OptionsArray(ratey) GetBaseWidget ]   -row 1 -column 2 -padx 0 

	    grid  [ $OptionsArray(startz) GetBaseWidget ]  -row 2 -column 0 -padx 0 
	    grid  [ $OptionsArray(stopz) GetBaseWidget ]   -row 2 -column 1 -padx 0
	    grid  [ $OptionsArray(ratez) GetBaseWidget ]   -row 2 -column 2 -padx 0 

	    grid  [ $OptionsArray(startt) GetBaseWidget ]   -row 3 -column 0 -padx 0 
	    grid  [ $OptionsArray(stopt) GetBaseWidget ]    -row 3 -column 1 -padx 0
	    grid  [ $OptionsArray(ratet) GetBaseWidget ]    -row 3 -column 2 -padx 0 

	    grid  [ $OptionsArray(blank) GetBaseWidget ]     -row 4 -column 0 
	    grid  [ $OptionsArray(autocrop) GetBaseWidget ]  -row 4 -column 1 -columnspan 2 

	    set v [ file rootname [  $OptionsArray(startx) GetBaseWidget ] ]

	    grid rowconfigure $v 5 -weight 100
	    #	    grid columnconfigure $v 3 -weight 100
	}
    }
    update idletasks


}
# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------



itcl::body bis_cropimage::Execute {  } {

    #    $this UpdateInputsFromContainer


    PrintDebug "bis_cropimage::Execute"
 #   puts stderr "Starting [ $this GetCommandLine full ]"


    set x0   [ $OptionsArray(startx) GetValue ]
    set x1   [ $OptionsArray(stopx) GetValue ]
    set dx   [ $OptionsArray(ratex) GetValue ]

    set y0   [ $OptionsArray(starty) GetValue ]
    set y1   [ $OptionsArray(stopy) GetValue ]
    set dy   [ $OptionsArray(ratey) GetValue ]

    set z0   [ $OptionsArray(startz) GetValue ]
    set z1   [ $OptionsArray(stopz) GetValue ]
    set dz   [ $OptionsArray(ratez) GetValue ]

    set t0   [ $OptionsArray(startt) GetValue ]
    set t1   [ $OptionsArray(stopt) GetValue ]
    set dt   [ $OptionsArray(ratet) GetValue ]

    set doblank [ $OptionsArray(blank) GetValue ]
    set autocrop [ $OptionsArray(autocrop) GetValue ]
    set autopad  [ $OptionsArray(autocroppad) GetValue ]

    set currentimage  [ $InputsArray(input_image) GetObject ]
    set currentresults [ $OutputsArray(output_image) GetObject ]



#    puts stderr "x = $x0:$dx:$x1"
#    puts stderr "y = $y0:$dy:$y1"
    #puts stderr "z = $z0:$dz:$z1"
#    puts stderr "t = $t0:$dt:$t1"

    set ori { 0.0 0.0 0.0 }
    
    if { $autocrop == "on" } {

	#puts stderr "Doing Autocrop ... $autopad"
	set ut [ vtkpxUtil [ pxvtable::vnewobj ]]
	set tmp [ vtkImageData [ pxvtable::vnewobj ]]
	$tmp ShallowCopy [  $currentimage GetImage ]

	$ut AutoCropImage $tmp $autopad
	set ori [ $tmp GetOrigin ]
	$tmp SetOrigin 0 0 0 

	$currentresults ShallowCopyImage $tmp
	$ut Delete
	$tmp Delete
    } else {
	set spa [ [ $currentimage GetImage ] GetSpacing ]
	set ori [ [ $currentimage GetImage ] GetOrigin ]
	set dim [ [ $currentimage GetImage ] GetDimensions ]
	set nc [ [ $currentimage GetImage ] GetNumberOfScalarComponents ]
	
	# Leave this as negative to enable padding in the other direction also
	if { $x0 < -256 } { set x0 -256 } 
	if { $y0 < -256 } { set y0 -256 } 
	if { $z0 < -256 } { set z0 -256 } 
	if { $t0 < 1 } { set t0 1 } 
	
	#puts "Bottom: $x0 $y0 $z0 $t0" 
	set max 4096
	if { $x1 > $max } { set x1 $max } 
	if { $y1 > $max } { set y1 $max } 
	if { $z1 > $max } { set z1 $max } 
	if { $t1 > $max } { set t1 $max } 
	#puts "Top:    $x1 $y1 $z1 $t1" 

	if { $x1 < $x0 } { set x1 [ expr [ lindex $dim 0 ] -1 ] }
	if { $y1 < $y0 } { set y1 [ expr [ lindex $dim 1 ] -1 ] }
	if { $z1 < $z0 } { set z1 [ expr [ lindex $dim 2 ] -1 ] }
	if { $t1 == 999 } { set t1 $nc }
	#puts "Top:    $x1 $y1 $z1 $t1" 

	set voi0  [ list   $x0 $y0 $z0 ]
	set voi1  [ list   $x1 $y1 $z1 ]
	set voisp [ list   $dx $dy $dz ] 

	#puts "Bottom: $x0 $y0 $z0 $t0" 
	#puts "Top:    $x1 $y1 $z1 $t1" 

	$OptionsArray(startx) SetValue $x0; 	$OptionsArray(stopx) SetValue $x1;   
	$OptionsArray(starty) SetValue $y0; 	$OptionsArray(stopy) SetValue $y1;   
	$OptionsArray(startz) SetValue $z0; 	$OptionsArray(stopz) SetValue $z1;   
	$OptionsArray(startt) SetValue $t0; 	$OptionsArray(stopt) SetValue $t1;   


	set trans  [  vtkIdentityTransform [ pxvtable::vnewobj ] ]	
	
	for { set i 0 } { $i <=2 } { incr i } {
	    set pos0 [ expr round([ lindex $voi0 $i ]) ]
	    set pos1 [ expr round([ lindex $voi1 $i ]) ]
	    set dpos [ expr $pos1 - $pos0 + 1 ]
	    set rat  [ lindex $voisp $i ] 
	    if { $rat <1 } { set rat 1 } elseif { $rat>50 } {set rat 50 }

	    if { $pos1 < $pos0 } { set pos1 [ expr $pos0 ] }
	    if { $dpos < 0 } { set dpos 0 } 
	    
	    set origin($i)  [ expr [lindex $ori $i ] + $pos0 * [ lindex $spa $i ]]
	    set spacing($i) [ expr [lindex $spa $i ] * double($rat) ]
	    set ext($i)     [ expr int(double($dpos)/double($rat)+0.5) ]
	    
	    #puts stderr "voisp = ${voisp} , voi0 = ${voi0}, voi1 = ${voi1} "
	    #puts stderr "Dimension = $i Origin($i) = $origin($i), spa=$spacing($i) ext=$ext($i)  (pos0=$pos0,pos1=$pos1, dpos=$dpos, rat=$rat)"
	}


	set tmp 0
	if { $dt !=1 || $t0 !=1 || $t1 != $nc } {
	    set tmp [ vtkImageData [ pxvtable::vnewobj ]]
	    set ut [ vtkpxUtil [ pxvtable::vnewobj ]]
#	    puts stdout "Extracting frames from [ expr int($t0 -1) ] to [ expr  int($t1 -1) ] with increment [ expr int($dt) ]"
	    $ut ExtractFrames $tmp [ $currentimage GetImage ] [ expr int($t0 -1) ] [ expr  int($t1 -1) ] [ expr int($dt) ]
	    $ut Delete
	} 


	set resl [ vtkbisImageReslice [ pxvtable::vnewobj ]]
	if { $tmp ==0 } {
	    $resl SetInput [ $currentimage GetImage ]
	} else {
	    $resl SetInput $tmp
	}
	$resl SetResliceTransform $trans
	$resl SetOutputSpacing $spacing(0) $spacing(1) $spacing(2)
	$resl SetOutputOrigin  $origin(0)  $origin(1)  $origin(2)
	$resl SetOutputExtent  0 [ expr $ext(0)-1 ] 0 [ expr $ext(1)-1 ] 0 [ expr $ext(2)-1 ]
	$resl SetInterpolationMode 0 
	$this SetFilterCallbacks $resl "Cropping Image"
	$resl Update
	
	
	if { $doblank == "on" } {
	    # Pad back to original size
	    set padresl [ vtkbisImageReslice [ pxvtable::vnewobj ]]
	    $padresl SetInput [ $resl GetOutput ]  
	    $padresl SetInformationInput [ $currentimage GetImage ]
	    $padresl SetResliceTransform $trans
	    $padresl SetInterpolationMode 0
	    $this SetFilterCallbacks $padresl "Blanking Image"
	    $padresl Update
	    set ori [ [ $padresl GetOutput ] GetOrigin ]
	    $currentresults ShallowCopyImage [ $padresl GetOutput ]
	    $padresl Delete
	} else {
	    $currentresults ShallowCopyImage [ $resl GetOutput ]
	}
	if { $tmp != 0 } {
	    $tmp Delete
	}
	$resl Delete
    }

    set ori [ [  $currentimage GetImage ] GetOrigin ]
    set img [ vtkImageData New ]
    $img ShallowCopy [ $currentresults GetImage ]
    set chng [ vtkImageChangeInformation New ]
    $chng SetInput $img
    $chng SetOutputOrigin  [ lindex $ori 0 ] [ lindex $ori 1 ] [ lindex $ori 2 ]
    $chng Update
    $currentresults ShallowCopyImage [ $chng GetOutput ]
    $img Delete

    $currentresults CopyImageHeader [ $currentimage GetImageHeader ]
    [ $currentresults GetImageHeader ] AddComment [ $this GetCommandLine full ] 

    #    puts stdout "Results = [ [ $currentresults GetImage ] GetOrigin ]"
    
    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_cropimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_cropimage [pxvtable::vnewobj]]
    $alg MainFunction 
}





