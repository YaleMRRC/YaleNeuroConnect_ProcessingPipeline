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

package provide pxitcloverlaytab 1.0

package require  labelframe 1.0
package require  pxtclutil  1.0
package require  pxvtable   1.0
package require  pxitclbaseimagecontrol 1.0
package require  pxitcltransform 1.0
package require  pxitcloverlaytool 1.0


itcl::class pxitcloverlaytabGUI {

    inherit pxitcloverlaytool
 
    public variable inputimagescallback 0
    public variable itcl_transform 0

    constructor { par args } {
	pxitcloverlaytool::constructor $par $args
    } {
	set itcl_transform [ [  pxitcltransform \#auto ] GetThisPointer ]
	
	#Use just the functional overlay part of the reslice control
	set compact_reslice_control 0

    }
    


    public  method ResliceFunctionalImage { force display } {
	if { $inputimagescallback != 0 } {
	    eval $inputimagescallback
	}
	return [ ::pxitcloverlaytool::ResliceFunctionalImage $force $display ]
    }
    


    public method CreateResliceControl { par } {

	#------------------------------------------------------------------------------------------
	#
	# Reslice Controls
	# ----------------
	#
	# Edited 01/25/06 by Marcello DiStasio to fit into surgery tool
	#
	#------------------------------------------------------------------------------------------

	#Three main frames
	set w $par
	set OCbackgroundcolor [$par cget -background]
	frame $w.m; 
	frame $w.p; 
	frame $w.q;  
	pack $w.m $w.p $w.q -side top -expand 1 -pady 1 -padx 1

	#Reslice Output Canvas
	set OC [canvas $w.m.imagecanvas -height 190 -width 480 -bg "$OCbackgroundcolor"];     pack $OC -fill both -expand 1

	#Interpolation frame
	label $w.p.1 -text "Interpolation Type:"
	tk_optionMenu $w.p.opt [ itcl::scope thisparam($this,resliceinterp) ] "NearestNeighbor" "Linear" "Cubic"
#	pack $w.p.1 $w.p.opt  -side left -expand f

	#----------------------------------------------------------------------------------------------------
	#Old Checkbuttons
	checkbutton   $w.q.1  -text "Bounds to Reference"  -variable [ itcl::scope thisparam($this,reslicetoreference) ]
	checkbutton   $w.q.2 -text "Scale By Jacobian"   -variable  [ itcl::scope thisparam($this,reslicescaleintensity) ]
	
	
	# 	    pack $w.q.1 $w.q.2  -side top -expand f -fill x
	checkbutton   $w.p.11 -variable [ itcl::scope thisparam($this,reslicewrappad) ] -text "Wrap"
	checkbutton   $w.p.12  -text "Automatically Reorient"  -variable [ itcl::scope thisparam($this,autoreorient) ]
	# 	    pack $w.p.11 $w.p.12  -side top -expand f -fill x
	#----------------------------------------------------------------------------------------------------

	return $OC
	
    }
    #------------------------------------------------------------------------------------------
    #-------------------End overloaded method CreateResliceControl-----------------------------
    #------------------------------------------------------------------------------------------


   # --------------------------------------------------------
   #    overloaded Create Overlay Control 
      # --------------------------------------------------------
    public method CreateFunctionalOverlayControl { parent } {

	set basewidget $parent
   	set w $parent
   	set OCbgcolor [$w cget -background]
	
  	frame $w.m -bg $OCbgcolor -pady 2; frame $w.m2 -bg $OCbgcolor; 
	frame $w.f0 -bg $OCbgcolor; frame $w.f1 -bg $OCbgcolor; frame $w.f2 -bg $OCbgcolor;
	pack $w.m $w.m2 $w.f0 $w.f1 $w.f2 -side top -expand f
	label $w.m.1 -text "Overlay Type:" -bg $OCbgcolor
  	tk_optionMenu $w.m.opt [ itcl::scope thisparam($this,overlaymode) ] "Positive" "Negative" "Both" 
	$w.m.opt configure -bg LightBlue3 -activebackground LightBlue1 
  	pack $w.m.1 $w.m.opt -side left -expand f
	
  	if { $disable_colormapchoice == 0 } {
	    
  	    label $w.m.c1 -text "Colormap:" -bg $OCbgcolor
  	    tk_optionMenu $w.m.copt [ itcl::scope thisparam($this,overlaycmapmode) ] "F1" "F2" "F3" 
  	    pack $w.m.c1 $w.m.copt -side left -expand f
  	} else {
  	    set thisparam($this,overlaycmapmode) F1
  	}
    
  	checkbutton $w.m.chk2 -variable [ itcl::scope thisparam($this,overlayanatcmapmode) ] -text "Normalize Anatomical" \
  	    -bg LightBlue3 -activebackground LightBlue1
  	pack $w.m.chk2 -side left -expand f  -padx {40 0}
	
  	# Clustering Stuff
  	# ----------------
  	global tcl_platform
	

  	label $w.m2.1 -text "Clustering:" -bg $OCbgcolor
  	set thisparam($this,cluster_threshold_scale) [ scale  $w.m2.s -orient horizontal  -from 0 -to 1000 -resolution 1.0 -showvalue 0 -length 150 -variable [ itcl::scope thisparam($this,cluster_threshold) ] ]
  	eval "bind $w.m2.s <ButtonRelease> { $this CreateOverlay }"
  	entry $w.m2.e -textvariable [ itcl::scope thisparam($this,cluster_threshold) ] -width 6 \
  	    -relief sunken -font { fixed 10 } -bg $OCbgcolor
	
  	label $w.m2.l1 -text "Prob: " -bg $OCbgcolor
  	set thisparam($this,cluster_threshold_prob) [ label $w.m2.l2 -text "1.0" -fg "blue" ]
	
  	pack $w.m2.1 $w.m2.s $w.m2.e $w.m2.l1  $w.m2.l2 -side left -expand t -fill x

    
  	set thisparam($this,overlay_minthresholdscale)  [ ::pxtclutil::CreateTriple $w.f0.0  "Low Threshold"   [ itcl::scope thisparam($this,overlaymin) ]  0.0 1000.0 0.1 10 95 ]
	$w.f0.0 configure -background $OCbgcolor -ipadx 10 -ipady {0 4}
  	set thisparam($this,overlay_maxthresholdscale)  [ ::pxtclutil::CreateTriple $w.f0.1  "High Threshold"  [ itcl::scope thisparam($this,overlaymax) ]  0.0 1000.0 0.1 10 95 ]
	$w.f0.1 configure -background $OCbgcolor -ipadx 10 -ipady {0 4}
  	::pxtclutil::CreateTriple $w.f0.2  "Inten. Thr"  [ itcl::scope thisparam($this,overlayinten) ]  -1.0 255.0 5 1 60
	$w.f0.2 configure -background $OCbgcolor -ipadx 10 -ipady {0 4}
	
  	checkbutton $w.f1.chk -variable [ itcl::scope thisparam($this,overlaysingleframe) ] \
  	    -text "Single\nComponent\nOnly" -bg LightBlue3 -activebackground LightBlue1
  	pack $w.f1.chk -side left -padx 5
  	set thisparam($this,overlay_componentscale)  [ ::pxtclutil::CreateTriple $w.f1.1 "Select Component:"  [ itcl::scope thisparam($this,overlaycurrentframe) ]  1 10 1 10 95 ] 
	$w.f1.1 configure -background $OCbgcolor -ipady {2 2} -ipadx 40
  	eval "bind $thisparam($this,overlay_componentscale) <ButtonRelease> \"$this UpdateOverlayRange\" "
	
  	frame $w.c -bg $OCbgcolor; pack $w.c -side bottom -expand 1 -fill x -pady {0 2} -padx 8
  	eval "button  $w.c.1  -text \"Force  Reslice!\" -command { $this ResliceFunctionalImage 1 1 } -background green4 -activebackground green"
  	eval "button  $w.c.2  -text \"Create Overlay!\" -command { $this CreateOverlay   } -background green3 -activebackground green -activeforeground blue"
  	pack $w.c.1 $w.c.2  -side left -expand 1 -fill x -padx 3
	
#	puts stderr "comp scale $thisparam($this,overlay_componentscale)"

    }
    
        
    public method GetTransformation { } {
	return [ $itcl_transform GetTransformation ]
    }
    
    public method SetTransformation { newtr args } {
	$itcl_transform CopyTransformation $newtr
    }
    
    public    method GetTransformationName { } {
	return [ $itcl_transform configure -filename ]
    }
    
    
}

