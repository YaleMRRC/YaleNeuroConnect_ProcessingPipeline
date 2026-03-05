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

package provide bis_guicompareutility 1.0
package require bis_guicontainer 1.0
package require pxitclsurface 1.0



itcl::class bis_guicompareutility {

    inherit bis_guicontainer

    constructor { } { $this InitializeGUICompareUtility  }

    # Create Input/Output GUI Controls for Objects in standalone mode
    protected method InitializeGUICompareUtility { }

    # -----------------------------------------------
    # Legacy Interface for pxitclmultisubject
    # -----------------------------------------------
    public    method SetImageToCompareControl { ctrl image }
    public    method SetCompareMean1  { image args } { SetImageToCompareControl $meanimagecontrol1   $image } 
    public    method SetCompareMean2  { image args } { SetImageToCompareControl $meanimagecontrol2   $image } 
    public    method SetCompareSigma1 { image args } { SetImageToCompareControl $sigmaimagecontrol1  $image } 
    public    method SetCompareSigma2 { image args } { SetImageToCompareControl $sigmaimagecontrol2  $image } 
    public    method SetCompareN1     { num } 
    public    method SetCompareN2     { num } 
    public    method ClearCompareSigma1 {  args } { catch { $sigmaimagecontrol1 ClearObject } }
    public    method ClearCompareSigma2 {  args } { catch { $sigmaimagecontrol2 ClearObject } }
    # -----------------------------------------------------


    public method ImagesModified { args }
    public method SetResultsFromObject { img obj }  

    # Other Stuff STORAGE
    protected variable inputoutputtab 0

    # GUI Stuff
    protected method CreateContainedAlgorithmsGUIs { nt }
    public    method DelayedCreateGUI { }

    # protected variables for GUIs
    protected    variable meanimagecontrol1 0
    protected    variable meanimagecontrol2 0
    protected    variable sigmaimagecontrol1 0
    protected    variable sigmaimagecontrol2 0
    protected    variable fourdimagecontrol1 0
    protected    variable fourdimagecontrol2 0

    protected variable comparetool 0
    protected variable comparefourdtool 0

    protected method  CreateImageCompareControl { origpar } 
    protected method  CreateImageFourDCompareControl { origpar } 

}


#------------------------------------------------------------------------------------------
itcl::body bis_guicompareutility::InitializeGUICompareUtility { } {

    set inputs { }

    set outputs { 
	{ output_image "Results Image" pxitclimage  ""  }
    }

    
    set scriptname "bis_guicompareutility"
    set category "Graphical-User-Interface-Module"
    set description " Utility Class for containing two image compare tools."
    set backwardcompatibility "See (parts of) pxitcloverlaytool.tcl"
    set authors "xenophon.papademetris@yale.edu."

    set completionstatus "ongoing  -- Xenios needs to revisit"

    # does not contain extract surface and mapfunctional
    set componentnamelist [ list  bis_ttest bis_imagecompare ]
    $this AddDefaultOptions
}



#------------------------------------------------------------------------------------------
::itcl::body bis_guicompareutility::DelayedCreateGUI { } {
    
    $this CreateContainedAlgorithmsGUIs $maintabnotebook
    set fullyinitialized 1
    return 1
}
# -----------------------------------------------------------------------------
::itcl::body bis_guicompareutility::CreateContainedAlgorithmsGUIs { nt } {

    set comparetool 0
    set comparefourdtool 0

    set l [ llength $componentlist ]
    for { set i 0 } { $i < $l } { incr i } {
	set alg [ lindex $componentlist $i ]
	if { [ $alg isa bis_ttest ] == 1 }  { 
	    set comparefourdtool $alg
	}
	if { [ $alg isa bis_imagecompare ] == 1 }  { 
	    set comparetool $alg
	}
	
    }

    #    puts stderr "Creating Image COmpare Control"

    $this CreateImageCompareControl [ $nt add -label "Image Compare" ]
    $this CreateImageFourDCompareControl [ $nt add -label "4D Image Compare" ]
    return 1
}

# -----------------------------------------------------------------------------------
itcl::body bis_guicompareutility::CreateImageCompareControl { origpar } {

    label $origpar.top -bg black -fg white -text "Statistical Comparison"
    pack $origpar.top -fill x -side top -expand f
    
    set statpar $origpar
    frame $statpar.bot -bg gray; 
    pack $statpar.bot -side bottom -expand f -fill x
    
    set meanimagecontrol1  [[ pxitclimageGUI \#auto  ] GetThisPointer ]
    set sigmaimagecontrol1 [[ pxitclimageGUI \#auto  ] GetThisPointer ]
    
    set meanimagecontrol2 [[ pxitclimageGUI \#auto  ] GetThisPointer ]
    set sigmaimagecontrol2 [[ pxitclimageGUI \#auto  ] GetThisPointer ]

    set nt1 [ iwidgets::tabnotebook $statpar.1 -tabpos n  -angle 45 -margin 2 -backdrop gray -raiseselect true  ]
    set nt2 [ iwidgets::tabnotebook $statpar.2 -tabpos n  -angle 45 -margin 2 -backdrop gray -raiseselect true   ]
    pack $nt1 $nt2 -side top -expand false -fill x -pady 1
    
    
    set clist [ list $meanimagecontrol1 $sigmaimagecontrol1 $meanimagecontrol2 $sigmaimagecontrol2 ]
    set dlist [ list "Mean 1" "Standard Deviation 1" "Mean 2" "Standard Deviation 2" ]
    set elist [ list $nt1 $nt1 $nt2 $nt2 ] 

    for { set i 0 } { $i<=3 } { incr i } {
	
	set ctrl [ lindex $clist $i ]
	set desc [ lindex $dlist $i ]
	set nt   [ lindex $elist $i ]

	set fr [ $nt add -label $desc ]

	$ctrl configure -description $desc
	$ctrl InitializeLite $fr.a 3
	#$ctrl AddFunction "$this SetFunctionalImage" "Display" "$this" 
	if { $i == 1 || $i == 3 } { 
	    $fr configure -background darkgray
	}
	pack $fr.a -side top -expand f -fill x -pady 0 -padx 0
	$ctrl configure -callback "$this ImagesModified 3d"
    }

    $nt1 view "Mean 1"
    $nt2 view "Mean 2"


    $comparetool SetGUIMode managed
    $comparetool SetMainTabScrollMode 0
    $comparetool CreateGUI $statpar.bot

    
}

# --------------------------------------------------------
itcl::body bis_guicompareutility::CreateImageFourDCompareControl { origpar } {

    label $origpar.top -bg black -fg white -text "4D Image Statistical Comparison"
    pack $origpar.top -fill x -side top -expand f

    set statpar $origpar

    frame $statpar.bot -bg gray; pack $statpar.bot -side bottom -expand f -fill x
    $comparefourdtool SetGUIMode managed
    $comparefourdtool SetMainTabScrollMode 0
    $comparefourdtool CreateGUI $statpar.bot
   
    set fourdimagecontrol1 [[ pxitclimageGUI \#auto  ] GetThisPointer ]
    set fourdimagecontrol2 [[ pxitclimageGUI \#auto  ] GetThisPointer ]

    set clist [ list $fourdimagecontrol1 $fourdimagecontrol2 ]
    set dlist [ list "4D Image 1" "4D Image 2" ]

    for { set i 0 } { $i<=1 } { incr i } {
	
	set ctrl [ lindex $clist $i ]
	set desc [ lindex $dlist $i ]

	set nm $statpar.fr$i 


	$ctrl configure -description $desc
	$ctrl InitializeLite $nm 3
	#	$ctrl AddFunction "$this SetFunctionalImage" "Display" "$this" 
	pack $nm -side top -expand f -fill x -pady 0 -padx 0
	$ctrl configure -callback "$this ImagesModified 4d"
    }

}
# --------------------------------------------------------------------------------------

::itcl::body bis_guicompareutility::ImagesModified { args } {

    if { $meanimagecontrol1 == 0 ||  $comparetool == 0 ||  $comparefourdtool ==  0 } {
	# GUI Not yet established
	return
    }
    
    set md [ lindex $args 0 ]

    if { $md == "4d" } {
#	puts stderr "updating comparefourdtool = $comparefourdtool"
	$comparefourdtool SetInput [ $fourdimagecontrol1 GetObject ]
	$comparefourdtool SetSecondInput [ $fourdimagecontrol2 GetObject ]
    }

    if { $md == "3d" } {
#	puts stderr "updating comparetool = $comparetool"
	$comparetool SetInput [ $meanimagecontrol1 GetObject ]
	$comparetool SetSecondInput [ $meanimagecontrol2 GetObject ]
	$comparetool SetInputObject first_sigma  [ $sigmaimagecontrol1 GetObject ]
	$comparetool SetInputObject second_sigma [ $sigmaimagecontrol2 GetObject ]
    }
}


#------------------------------------------------------------------------------------------
::itcl::body bis_guicompareutility::SetResultsFromObject { img obj }  { 

    set out [ $this GetFirstOutputObject ]
    $out ShallowCopy $img
    PrintDebug "In $this SetResultsFromObject, going to updatecontainerwithoutput, $containerobject\n\n\n"

    $containerobject SetResultsFromObject $out $this
}
#------------------------------------------------------------------------------------------



itcl::body bis_guicompareutility::SetCompareN1     { num } {
    if { $comparetool !=0 } {
	$comparetool SetOptionValue n1 $num
    }
}

itcl::body bis_guicompareutility::SetCompareN2     { num }  {
    if { $comparetool ==0 } {
	return 
    }
    
    if { $comparetool !=0 } {
	$comparetool SetOptionValue n2 $num
    }
}


itcl::body bis_guicompareutility::SetImageToCompareControl { ctrl image } {
    if { $ctrl ==0 } {
	return 
    }
    [ $ctrl GetObject ] ShallowCopy $image; 
    $ctrl Update 
}


