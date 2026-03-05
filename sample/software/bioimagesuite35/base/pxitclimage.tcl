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

package provide pxitclimage 1.0

# 	$Id: pxitclimage.tcl,v 1.2 2003/08/14 17:49:42 xenios Exp xenios $	




package require  pxitclobject  1.0
package require  pxtcluserprefs 1.0
package require pxtclreadvarianheader

# -------------------------------------------------------------------
# Definition of pxitclimage
#
#    a class that encapsulates an image (vtkImageData)
#            its imageheader (vtkbisImageHeader) , filename and status
# -------------------------------------------------------------------

itcl::class pxitclimage {

    inherit pxitclobject

    # --- begin variable def -----

    public variable status 
    protected variable img  0
    protected variable lookuptable 0
    protected  variable imageheader 0
    protected  common forceoutputformat 0
    public     variable lastdicomlist ""
    public     common forcebioimagesuitecoordinates 1
    
    # --- end of variable def -----

    constructor { } {
	pxitclobject::constructor 
    } {
	CreateNewImage
	UpdateStatus    
    }

    destructor  { $img Delete     }


    # --- begin method def -----
    public method GetObject { } { return $img }
    public method GetType { } { return [ $img GetDimensions ] }
    public method GetDescription { } 
    public method UpdateStatus { } { set status [ $img GetDimensions ]  }
    public method Copy   { obj args }
    public method Clear { } 
    public method UnLoad { } { return [ Clear ] }

    # args  1=filename 2=description 3=parent object (save 4=force analyze)
    public method Load      { args }
    public method LoadDICOM { fname { petcenter 1 } { parobj 0 } }
    public method LoadVarian { fname  { parobj 0 } { flipdti 0 } }
    public method ISPETDICOM { fname }
    public method Save      { args }


    # mode = 0 auto, 1= force analyze, 2 = force nifti (.hdr/.img)
    public method SetOutputFormat { mode }
    public method SetForceInputOrientation { mode } { 
	if { $mode == "Off" } {
	    set forcebioimagesuitecoordinates 0
	} else {
	    set forcebioimagesuitecoordinates 1
	}
    }
	    

    public method LoadLookupTable { cname }
    public method SaveLookupTable { cname }
    public method CreateLookupTable { }

    # Methods additional to pxitclobject
    
    public method GetImage { } { return $img }
    public method GetImageHeader { } { return $imageheader }
    public method GetLookupTable { } { return $lookuptable }
    public method SetLookupTable { cmap } 

    public method AddComment { cmt } { [ $this GetImageHeader ] AddComment $cmt 0 }

    public method GetLongDescription { } 
    public method GetShortDescription { } 
    public method GetSize { } { return [ $this GetImageSize ] }
    public method GetImageSize { } 
    public method IsSameDisplaySize { other } 


    public method DeepCopyImage    { newimg } { CopyImage $newimg 1    }
    public method ShallowCopyImage { newimg } { CopyImage $newimg 0    }
    public method CopyImage   { newimg mode }
    public method CopyImageHeader  { newheader }
    public method CopyImageHeaderAndFixImage  { newheader }

    public method GetOrientation { }
    public method GetIntensityScale { }
    public method GetIntensityOffset { }
    public method SetOrientationDirect { ori } 
    public method GetOrientationName { }
    public method SetFromAnalyzeSource { ana }
    public method SetFromAnalyzeSourceOld { ana }
    public method CreateNewImage { } 

    # Procedures to Just Set Filename
    public method Browse { description }

    # Common Complex Image Processing Routines
    public method FlipImage { mode }

    # Static Method to Get Image List types
    public proc GetImageTypeList { mode } 

    # Does Image Exist on Disk
    public method DoesImageExistOnDisk { } 
    public method SplitFileName { } 

    # Compare with FileName
    public method CompareTo  { fname { thr 0.001 } }
    public method CorrelateWith  { fname { thr 0.9 } }

    # --- end method def -----
}

# ------------------- End of Header ---------------------------------

itcl::body pxitclimage::SplitFileName { } {

    if { $filename == "" } {
	return 0
    }

    set fname $filename
    set ext [ file extension $fname ]
    set ext2 ""
    if { $ext == ".gz" } {
	set fname [ file rootname $fname ]
	set ext   [ file extension $fname ]
	set ext2 ".gz"
    }

    return [ list $fname ${ext}${ext2} ]
}

# ---------------------------------------------------------------------

itcl::body pxitclimage::DoesImageExistOnDisk { } {

    if { $filename == "" } {
	return 0
    }

    set fname $filename

    set ext [ file extension $fname ]
    if { $ext == ".gz" } {
	set fname [ file rootname $fname ]
	set ext   [ file extension $fname ]
    }

    if { $ext == ".nii"  || $ext == ".vt" || $ext == ".vtk" } {
	if { [ file exists $fname ] == 1 || [ file exists ${fname}.gz ] ==1 } {
	    return 1
	}
    }
    
    set f1 $fname
    set f2 [ file rootname $fname].img

    set a1 0;
    set s2 0;
    if { [ file exists $f1 ] || [ file exists ${f1}.gz ] } {
	set a1 1
    }

    if { [ file exists $f2 ] || [ file exists ${f2}.gz ] } {
	set a2 1
    }

    if { $a1 == 1 && $a2 ==1 } {
	return 1
    }
    return 0
}



itcl::body pxitclimage::GetImageTypeList { mode } {

    global pxtcl_pref_array
    
    set typelist { {"Analyze/NIFT1 Files" { .hdr .hdr.gz .nii .nii.gz }}}


    if { $mode == "save" } {
	lappend typelist {"VTK Files" {.vt*}}
	return $typelist
    }

    set r 0
    catch { 
	set r [ vtkbisDICOMReader New ]
	lappend typelist {"DICOM Files" {.dcm *.DCM}}
	$r Delete
    }
    
    lappend typelist {"Varian Files" {.fdf *.FDF}}
	
    if { $pxtcl_pref_array(MincImageFormat) == "Enabled" } {
	lappend typelist {"MINC Files" {.mnc}}
    }
    
    lappend typelist {"VTK Files" {.vt*}}
    lappend typelist {"All Files" {*}}
    return $typelist
}

itcl::body pxitclimage::CreateNewImage { } {

    catch { $img Delete }

    set img [ vtkImageData [ pxvtable::vnewobj ]]
    $img SetDimensions 1 1 1
    $img SetWholeExtent 0 0 0 0 0 0
    $img SetExtent 0 0 0 0 0 0
    $img AllocateScalars

    catch { $imageheader Delete }
    set imageheader [ vtkbisImageHeader [ pxvtable::vnewobj ]]
    $imageheader  CreateHeader $img 0

}

# mode = 0 auto, 1= force analyze, 2 = force nifti (.hdr/.img)
itcl::body pxitclimage::SetOutputFormat { mode } {
    if { $mode < 0 || $mode > 2 } {
	return $fourceoutputformat
    }
    set forceoutputformat $mode
    set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
    $anaw SetForceOutputFileFormat $forceoutputformat
    $anaw Delete

    return $forceoutputformat
}

itcl::body pxitclimage::Copy   { obj args } {

    set ispxitclimage 0
    catch { if { [ $obj isa pxitclimage ] == 1 } {set ispxitclimage 1  } }
    if { $ispxitclimage  == 0 } { return }

    set mode 0
    if { [ llength $args ] > 0 } {
	set mode [ expr [ lindex $args 0 ] > 0 ]
    }

    set oldimg [ $obj GetImage ] 
    CopyImage $oldimg $mode
    SetLookupTable [ $obj GetLookupTable ]
    set filename    [ $obj cget -filename ]
    $this CopyImageHeader [ $obj GetImageHeader ]
    
    UpdateStatus
}
# ----------------------------------------------------------
itcl::body pxitclimage::CopyImage { newimg mode } {

    set isimagedata 0
    catch {
	if { [ $newimg IsA "vtkImageData" ] == 1 } {
	    set isimagedata 1
	}
    }
    if { $isimagedata == 0 } {return  }

    set mode [ expr $mode > 0 ]


    catch { $img Delete }
    set img [ vtkImageData [ pxvtable::vnewobj ]]

    scan [ $newimg GetDimensions ] "%d %d %d" x1 y1 z1
    set x1 [ expr $x1 - 1]
    set y1 [ expr $y1 - 1]
    set z1 [ expr $z1 - 1]

    if { $mode == 0 } {
	$img ShallowCopy $newimg
    } else {
	$img DeepCopy $newimg
    }
    $imageheader ReconcileHeader $img 0
    UpdateStatus
}


itcl::body pxitclimage::CopyImageHeader { newheader } {

    set isimageheader 0
    catch {
	if { [ $newheader IsA "vtkbisImageHeader" ] == 1 } {
	    set isimageheader 1
	}
    }
    if { $isimageheader == 0 } { return }

    $imageheader CopyHeader $newheader 
    $imageheader ReconcileHeader $img 0
    $this UpdateStatus
}

itcl::body pxitclimage::CopyImageHeaderAndFixImage { newheader } {

    set isimageheader 0
    catch {
	if { [ $newheader IsA "vtkbisImageHeader" ] == 1 } {
	    set isimageheader 1
	}
    }
    if { $isimageheader == 0 } { return }

    $imageheader CopyHeader $newheader 
    $imageheader ReconcileImage $img 0
    $imageheader ReconcileHeader $img 0
    $this UpdateStatus
}

# ----------------------------------------------------------
itcl::body pxitclimage::Clear { } {
    catch { $img Delete }
    CreateNewImage
    set filename    ""
    UpdateStatus
}
# ----------------------------------------------------------
itcl::body pxitclimage::SetOrientationDirect { ori } {
    if { $ori <0 || $ori > 3 } {
	return
    }
    
    $imageheader SetOrientation $ori
    return

}
itcl::body pxitclimage::GetOrientation { } {
    
    return [ $imageheader GetOrientation ]
}

itcl::body pxitclimage::GetIntensityScale { } {
    
    return [ $imageheader GetIntensityScale ]
}

itcl::body pxitclimage::GetIntensityOffset { } {
    
    return [ $imageheader GetIntensityOffset ]
}



itcl::body pxitclimage::GetOrientationName { } {
    
    set raw [ $imageheader GetOrientation ]
    set orientation [ $imageheader MapOrientationToOldStyle $raw ]
    set name [ $imageheader GetOrientationCode ]

    switch -exact $orientation {
	"1" { return "Coronal $name" }
	"2" { return "Sagittal $name" } 
	"3" { return "Polar" } 
    }
    
    return "Axial $name" 
}
# ----------------------------------------------------------
itcl::body pxitclimage::GetImageSize { } {
    scan [ $img GetDimensions ] "%d %d %d" x1 y1 z1
    return [ expr $x1 * $y1 * $z1 ]
}

itcl::body pxitclimage::IsSameDisplaySize { other } {
    if { $other == $img } {
	return 1
    }
    if { $other == 0 } {
	return 0
    }

    set otherimg [ $other GetImage ]

    scan [ $img GetDimensions ] "%d %d %d" x1 y1 z1
    scan [ $otherimg GetDimensions ] "%d %d %d" x2 y2 z2

    scan [ $img GetSpacing ] "%f %f %f" a1 b1 c1
    scan [ $otherimg GetSpacing ] "%f %f %f" a2 b2 c2

    set l1 [ list $x1 $y1 $z1 $a1 $b1 $c1 ]
    set l2 [ list $x2 $y2 $z2 $a2 $b2 $c2 ]
    
    set sum 0
    for { set i 0 } { $i < [ llength $l1 ]  } { incr i } {
	set d [ expr abs([lindex $l1 $i]-[ lindex $l2 $i ] )]
	if { $d > 0.00001 } {
	    incr sum
	}
    }

    if { $sum ==0 } {
	return 1
    }
    return 0
}

# ----------------------------------------------------------
itcl::body pxitclimage::GetLongDescription { } {

    if { $imageheader !=0 } {	
	set l [ $imageheader GetHeaderDescription -1 ]
	regsub -all "\t" $l " " l
	return "$l\n*${filename}*"
    }

    scan [ $img GetDimensions ] "%d %d %d" x1 y1 z1
    scan [ $img GetSpacing    ] "%f %f %f" s1 s2 s3
    scan [ $img GetOrigin     ] "%f %f %f" o1 o2 o3
    set t1 [ $img GetNumberOfScalarComponents ] 
    
    set line [ format "Dimensions %dx%dx%d Comp=%d Orientation = [ GetOrientationName]\nSpacing=%.3fx%.3fx%.3f origin=(%.1f %.1f %.1f)" $x1 $y1 $z1 $t1 $s1 $s2 $s3 $o1 $o2 $o3 ]
    set line  "name=$this\n\t$line\n\tFilename= *${filename}*"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitclimage::GetDescription { } {
     
    if { $imageheader !=0 } {

	
	set l [ $imageheader GetHeaderDescription -1 ]
	regsub -all "\t" $l " " l
	set l2 "${l}\n*${filename}*"
	return $l2
    }

    scan [ $img GetDimensions ] "%d %d %d" x1 y1 z1
    scan [ $img GetSpacing    ] "%f %f %f" s1 s2 s3
    scan [ $img GetOrigin     ] "%f %f %f" o1 o2 o3
    set t1 [ $img GetNumberOfScalarComponents ] 
    
    set line [ format "Dimensions %dx%dx%d fr=%d,Orientation = [ GetOrientationName]\nSpacing=%.3fx%.3fx%.3f origin=(%.1f %.1f %.1f)" $x1 $y1 $z1 $t1 $s1 $s2 $s3 $o1 $o2 $o3 ]
    set line  "$line\nFilename=*${filename}*\n"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitclimage::GetShortDescription { } {
    
    scan [ $img GetDimensions ] "%d %d %d" x1 y1 z1
    set t1 [ $img GetNumberOfScalarComponents ] 
   
    set line [ format "%dx%dx%d,%d"  $x1 $y1 $z1 $t1 ]

    set line  "[ file tail $filename] [ GetOrientationName ] $line"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitclimage::SetFromAnalyzeSource { ana } {

    #puts stderr "In Set From Analyze Source"

    if { [ $ana IsA vtkpxAnalyzeImageSourceOld ] == 1 } {
	return [ $this SetFromAnalyzeSourceOld $ana ]
    }

    global pxtcl_pref_array
    if { [ $ana IsA vtkpxAnalyzeImageSource ] == 0 } {
	return 0
    }

    ShallowCopyImage [ $ana GetOutput ]
    CopyImageHeader  [ $ana GetImageHeader ]
    $imageheader ReconcileImageIntensityRange $img

    if { [ GetImageSize ] < 1 } {
	Clear
    }

    #    #puts stderr "In setfromana [ $imageheader GetHeaderDescription 0 ]"
    set filename     [ pxtclutil::GetAbsoluteFileName [ $imageheader GetFileName ] ]


    set ok 1

    if { $pxtcl_pref_array(ImageColormaps) == 1 } {
	set cname "[ file root $filename ].cmap"

	if { [ file exists $cname ] } {
	    LoadLookupTable $cname
	    set ok 2
	}
    }
    UpdateStatus
    return  $ok
}
# ----------------------------------------------------------
itcl::body pxitclimage::SetFromAnalyzeSourceOld { ana } {

    global pxtcl_pref_array
    #puts stderr "In Set From Analyze Source Old"

    if { [ $ana IsA vtkpxAnalyzeImageSourceOld ] == 0 } {
	return 0
    }

    ShallowCopyImage [ $ana GetOutput ]
    if { [ GetImageSize ] < 1 } {
	Clear
    }

    catch { set orientation  [ $ana GetOrientation ] }
    if { $orientation !=0 && $orientation !=1  && $orientation !=2  && $orientation !=3  } {
	#puts stderr "Input Orientation = $orientation"
	set orientation 0
    }
    set imageheader [ vtkbisImageHeader [ pxvtable::vnewobj ]]
    $imageheader  CreateHeader $img 0
    $imageheader  SetOrientation $orientation

    set filename     [ pxtclutil::GetAbsoluteFileName [ $ana GetFilePrefix ] ]
    #puts stderr "In Set From Analyze Source Old $filename"
    set ok 1

    if { $pxtcl_pref_array(ImageColormaps) == 1 } {
	set cname "[ file root $filename ].cmap"

	if { [ file exists $cname ] } {
	    LoadLookupTable $cname
	    set ok 2
	}
    }
    UpdateStatus
    #puts stderr "In Set From Analyze Source Old $filename $ok"
    return  $ok
}

# ----------------------------------------------------------
itcl::body pxitclimage::Browse { description } {

    set f2path [ file dirname $filename ]
    set f2tail [ file tail    $filename ]
	
    set typelist { {"Analyze/NIFT1 Files" { .hdr .hdr.gz .nii .nii.gz }}}
    set fname  [tk_getOpenFile -title "Get Filename for $description" -filetypes $typelist -initialfile $f2tail -initialdir $f2path ]   
    if { [ string length $fname ] > 0 } {
	set filename $fname
	return 1
    }
    return 0
}
# ----------------------------------------------------------
itcl::body pxitclimage::Load { args } {

    global pxtcl_pref_array

    set len [ llength $args ]
    if { [ string length $filename ] == 0 && $len == 0 } { return  }


    if { $len < 1 } {
	set fname $filename
    } else  { 
	set fname [ lindex $args 0 ] 
    }

    if { $len > 1 } { 
	set desc [ lindex $args 1 ]
    } else {
	set desc "Image"
    }

    set parobj 0;  if { $len > 2 } {	set parobj [ lindex $args 2 ]    }

    if { [ string length $fname ] == 0 } {
	set typelist  [ ::pxitclimage::GetImageTypeList load ]
	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set fname  [tk_getOpenFile -title "Load $desc" -filetypes $typelist -initialfile $f2tail -initialdir $f2path ]   
    }
    

    if { [ string length $fname ] <1 } {
	return 0
    }

    set ext [ file extension $fname ]
    set haslookuptable 0

    set f $fname

    set ext [ file extension $f ]
    set allok 1

    if { $ext == ".gz" } {
	set ext [ file extension [ file root $f ]]
    }

    set ext2 [ string range $ext 1 end ]

    set alldone 0

    if { $ext == ".png" || $ext == ".PNG" || $ext == ".jpg" || $ext == ".jpeg" || $ext == ".JPG" || $ext == ".JPEG" } {
	
	if { $ext == ".png" || $ext == ".PNG" } {
	    set ana [ vtkPNGReader New ]
	} else {
	    set ana [ vtkJPEGReader New ]
	}
	$ana SetFileName $f
	if { $parobj !=0 } { $parobj SetFilterCallbacks $ana "Reading $ext Image" ; $parobj	WatchOn }
	$ana Update
	$this ShallowCopyImage [ $ana GetOutput ]
	$this configure -filename $f
	if { $parobj !=0 } {  $parobj  WatchOff }
	set alldone 1
	$ana Delete
    } elseif { $ext == ".vt" || $ext == ".vtk" } {
	set ana [ vtkStructuredPointsReader [ pxvtable::vnewobj ]]
	$ana SetFileName $f
	if { $parobj !=0 } { $parobj SetFilterCallbacks $ana "Reading Image" ; $parobj	WatchOn }
	$ana Update
	$this ShallowCopyImage [ $ana GetOutput ]
	$this configure -filename $f
	if { $parobj !=0 } {  $parobj  WatchOff }
	set alldone 1
	$ana Delete
    } elseif { $ext == ".vtc" } {
	set ana [ vtkafBVImageReader [ pxvtable::vnewobj ]]
	if { $parobj !=0 } { $parobj SetFilterCallbacks $ana "Reading Image" ; $parobj WatchOn }
	$ana Load $f
	$this ShallowCopyImage [ $ana GetOutput ]
	$this configure -filename $f
	$imageheader SetOrientation [ $ana GetOrientation ]
	if { $parobj !=0 } {  $parobj  WatchOff }
	$ana Delete
	set alldone 1
    } elseif { $ext == ".fdf" } { 
    # Varian Reader
	set ok [ $this LoadVarian $fname  $parobj ]
	if { $ok == 0 } {
	    ::pxtclutil::Warning "Failed to Load Image $fname as Varian fdf"
	}
	set allok $ok
	set alldone 1
    } elseif { $ext == ".mnc" } {
	set ana [ vtkpxMINC2ImageReader [ pxvtable::vnewobj ]]
	if { $parobj !=0 } { $parobj SetFilterCallbacks $ana "Reading Image" ; $parobj WatchOn }
	set ok [ $ana Load $f ]
	set alldone 1
	if { $ok > 0 } {
	    $this ShallowCopyImage [ $ana GetOutput ]
	    $this configure -filename $f
	    $imageheader SetOrientation [ $ana GetOrientation ]
	    [ $this  GetImage ] SetOrigin 0 0 0
	} else {
	    ::pxtclutil::Warning "Failed to Load Image $f -- maybe it is not in MINC2 format."
	    set allok 0
	}
	if { $parobj !=0 } {  $parobj  WatchOff }
	$ana Delete
    } elseif { $ext != ".nii" && $ext !=".hdr" && $ext!=".img" } {
	set r [ vtkbisDICOMReader New ]
	$r CreateNIFTIHeaderOff
	set ok [ $r CanReadFile $f ]
	$r Delete
	if { $r > 0 } {
	    set ok [ $this LoadDICOM $fname 1  $parobj ]
	    if { $ok == 0 } {
		::pxtclutil::Warning "Failed to Load Image $fname as DICOM"
	    }

	    set allok $ok
	    set alldone 1
	}
    }


    if { $alldone == 0 } {
	set ana [vtkpxAnalyzeImageSource [ pxvtable::vnewobj ] ]
	if { $parobj !=0 } { $parobj SetFilterCallbacks $ana "Reading Image" ; $parobj WatchOn }
	$ana   SetForceStandardOrientation $forcebioimagesuitecoordinates 
	set ok [ $ana Load $f ]

	if { $ok > 0 } {
	    $this SetFromAnalyzeSource $ana
	} else {
	    ::pxtclutil::Warning "Failed to Load Image $f"
	    set allok 0
	}
	if { $parobj !=0 } {  $parobj  WatchOff }
	$ana Delete
    }

    if { $allok == 0 } {
	return $allok
    }
    
    if { $haslookuptable != 2 } {
	catch { $lookuptable Delete } 
	set lookuptable 0
    }

    return 1
}

# ----------------------------------------------------------
itcl::body pxitclimage::LoadDICOM { fname { petcenter 1 } { parobj 0 } } {


#    puts stdout "Starting $fname $petcenter $parobj\n\n"

    set lastdicomlist ""
    set dodicom 0
    catch { 
	set r [ vtkbisDICOMReader New ]
	set dodicom 1
	$r Delete
    }

    if { $dodicom == 0 } {
	puts stderr "This version of BioImage Suite can not read DICOM"
	return 0
    }

    # --  Jeetu's notes on 4D
    #
    #  (0020,0012) IS [1 ]                                               # 2,1 Acquisition Number
    #  (0020,0013) IS [2 ]                                               # 2,1 Instance Number

    # For anatomical images the acquisition number stays same and instance number is effectively frame
    # For fMRI images the acquisition number increases per time and instance number stays constant
    #
    # 0020,0012 -- fmri Acquis
    
    set fnamelist 0

    if { $petcenter > 0  } {
	# Use special rules to create filename list 
	set fnamelist [ $this ISPETDICOM $fname ] 
    }

    if { $fnamelist == 0 } {
	set dname [ file normalize [ file dirname $fname ] ]
	set fnamelist ""
	catch { set fnamelist [ lsort [ glob [ file join $dname * ]] ] }
	if  { $fnamelist == "" } {
	    return 0
	}
	set fnamelist [ lsort -unique [ concat [ file normalize $fname ] $fnamelist ] ]
    }


    #    puts stdout "fnamelist = $fnamelist"


    set sortimglist ""
    set studyid ""
    set seriesid ""
    set seriestime ""

    set imglist  ""
    set found 0
    set mosaic 0
    set dwimode 0
    set dwidirlist ""
    set dwizlist ""

    set mos_w 0
    set mos_h 0
    set mos_d 0
    set mos_spa 0
    set r [ vtkbisDICOMReader New ]
    $r CreateNIFTIHeaderOff
    set ok [ $r CanReadFile $fname ]
    if { $ok == 3 } {
	$r SetFileName $fname
	$r Update
	    
	set studyid  [ $r GetStudyUID ]
	set seriesid [ $r GetSeriesUID ]
	set found 1

	if { [ $r GetIsMosaic  ] > 0 } {
	    set mosaic 1
	    set mos_w [ $r GetMosaicWidth ]
	    set mos_h [ $r GetMosaicHeight ]
	    set mos_d [ $r GetMosaicDepth ]
	    set seriestime [ $r GetTimeFrame ]
	    set mos_spa [ [ $r GetOutput ] GetSpacing ]
	} 

	if { [ $r GetDWIMode ] > 0 } {
	    set dwimode 1
	    set dwi_spa [ [ $r GetOutput ] GetSpacing ]
	}
    }
    puts stdout "$fname Mosaic [ $r GetIsMosaic ] , DWI = [ $r GetDWIMode ]"
    $r Delete
    
    if { $found == 0 } {
	return 0
    }
    
    set n [ llength $fnamelist ]

    for { set i 0 } { $i < $n  } { incr i } {
	set r [ vtkbisDICOMReader New ]
	$r CreateNIFTIHeaderOff

	set testname [ lindex $fnamelist $i ]
	set ok [ $r CanReadFile $testname ]
	
	if { $ok == 3 } {
	    #	    puts stdout "Setting Filename $testname"
	    $r SetFileName $testname
	    $r Update
	    set sid [ $r GetStudyUID ]
	    set sno [ $r GetSeriesUID ]


	    if { ( $sid == $studyid && $seriesid == $sno ) } {
		set rt [ $r GetReferenceTime ]
		if { $rt =="" } {
		    # FMRI Hack
		    set rt [ $r GetTimeFrame ]
		}
		
		set toadd 1
		if { $mosaic == 1 } {
		    if { $mos_w != [ $r GetMosaicWidth ] || $mos_h != [ $r GetMosaicHeight ] } {
			set toadd 0
		    }
		} 

		if { $dwimode >= 1 && $toadd ==1 } {
		    set dw [ $r GetDWIMode ]
		    set dr [ $r GetDWIDirections ]
		    set bv [ $r GetDWIBValue ]
		    set v "$dw,[ lindex $dr 0],[lindex $dr 1 ],[lindex $dr 2],$bv"
		    set ind [ lsearch -exact $dwidirlist $v ]
		    if { $ind == - 1 } {
			#			puts stdout "Appending direction $v"
			lappend dwidirlist $v
		    } else {
			#			puts stdout "$v already there -> [ lindex $dwidirlist $ind ]"
		    }
		    lappend dwizlist [ $r GetZPosition ]
		    #		    puts stdout "\t\t\t Adding  $testname"
		    lappend imglist [ list $testname [ $r GetZPosition ] [$r GetX0 ] [ $r GetY0 ] [ $r GetZ0 ] $v $sid $sno ]
		    set toadd 0
		}
		
		if { $toadd > 0  } {
		    lappend imglist [ list $testname [ $r GetZPosition ] [$r GetX0 ] [ $r GetY0 ] [ $r GetZ0 ] $rt $sid $sno ]
		}
	    } else {
		#puts stdout "Not matching $dwimode  $sno1 --> $seriesid1"
	    }
	}
	$r Delete
    }

    
    if { $dwimode > 0 } {
	set alldirections  $dwidirlist 
	set dwizlist [ lsort -unique  -real -increasing $dwizlist ]
	#	puts stdout "Alldirections = $alldirections"

	set n [ llength $imglist ]
	set tmp $imglist
	set imglist ""
	for { set i 0 } { $i < $n } { incr i } {
	    set elem [ lindex $tmp $i ] 
	    set d [ lindex $elem 5  ]
	    set ind [ lsearch  $alldirections $d ]
	    if { $ind == - 1 } {
		puts stdout "Bad Element $elem\n"
		for { set kk 0 } { $kk < [ llength $elem ] } { incr kk } {
		    puts stdout "$kk --> [ lindex $elem $kk ]"
		}
	    }
	    set newelem [ list [ lindex $elem 0 ] [ lindex $elem 1 ] $ind [ lindex $elem 2 ] [ lindex $elem 3 ] [ lindex $elem 4 ] [ lindex $elem 5  ] ]
	    lappend imglist $newelem
	}
    }

    if { [ llength $imglist ] == 0 } {
	return 0
    }


    # Double sort for time purposes
    # First sort in space
    if { $mosaic != 0 } {
	set sortimglist  [ lsort -real -increasing -index 5 $imglist ]
    } elseif { $dwimode !=0 } {
	set sortimglist  [ lsort -ascii -increasing -index 5  $imglist ]
	set sortimglist  [ lsort -real -increasing -index 1  $sortimglist ]
    } else  {
	set sortimglist [ lsort -real -increasing -index 1 $imglist ]
    }

#    puts stdout "\n\n Sorted List\n"
#    for { set i 0 } { $i < [ llength $sortimglist ] } { incr i } {
#	puts stdout "$i --> [ lindex $sortimglist $i ]"
#    }


#    pxtkprint "\n ------------------------------- \n Beginning to read $studyid, $seriesid\n"
    set sar [ vtkStringArray New ]
    set n [ llength $sortimglist ]

    set lastdicomlist $sortimglist

    for { set i 0 } { $i < $n } { incr i } {
	$sar InsertNextValue  [ lindex [ lindex $sortimglist $i ] 0 ]
    }
    
    set zflip 0

    if { $mosaic != 0 } {
	set zsp [ lindex $mos_spa 2 ]
	set zflip 0
    } elseif { $dwimode !=0 } { 
	set zsp 1.0
	set zflip 0
	if { [ llength $dwizlist ] > 1 } {
	    set zsp [ expr [ lindex $dwizlist 1 ] - [ lindex $dwizlist 0 ]]
	}
    } elseif { [ llength $sortimglist ] > 1 } {
	set z [ expr [ lindex [ lindex $sortimglist 1 ] 4 ] -  [ lindex [ lindex $sortimglist 0 ] 4 ] ]
	set x [ expr [ lindex [ lindex $sortimglist 1 ] 2 ] -  [ lindex [ lindex $sortimglist 0 ] 2 ] ]
	set y [ expr [ lindex [ lindex $sortimglist 1 ] 3 ] -  [ lindex [ lindex $sortimglist 0 ] 3 ] ]
	set zsp [ expr sqrt($x*$x+$y*$y+$z*$z) ]
	#	puts stderr "1=[ lindex $sortimglist 1 ]"
	#	puts stderr "0=[ lindex $sortimglist 0 ]"
	#	puts stderr "x=$x, y=$y, z=$z zsp=$zsp"
	
	if { $zsp < 0.0 } {
	    set zsp [ expr abs($zsp)  ]
	    set zflip 1
	}
    } else {
	set zsp 0.0
	set zflip 0
    }
    
    set ana [ vtkbisDICOMReader New ]
    if { $parobj !=0 } { $parobj SetFilterCallbacks $ana "Reading DICOM Image" ; $parobj	WatchOn }
    
    $ana SetForceZSpacing  $zsp
    $ana SetFlipZ $zflip
    $ana SetFileNames $sar
    $ana Update




    if { $mosaic > 0 } {
	set flt [ vtkbisSiemensMosaicConverter New ]
	#	$flt DebugOn
	$flt SetInput [ $ana GetOutput ]
	$flt SetMosaicWidth  $mos_w
	$flt SetMosaicHeight $mos_h
	$flt SetMosaicDepth  $mos_d
	$flt Update
	$this ShallowCopyImage [ $flt GetOutput ]
	$flt Delete
    } elseif { $dwimode > 0 } {
	set flt [ vtkbisSiemensDWIArrange New ]
	$flt SetInput [ $ana GetOutput ]
	$flt SetNumberOfSlices  [ llength $dwizlist ] 
	$flt Update
	$this ShallowCopyImage [ $flt GetOutput ]
	$flt Delete
    } else {
	$this ShallowCopyImage [ $ana GetOutput ]
    }
    $this CopyImageHeader  [ $ana GetImageHeader ]
    $imageheader ReconcileImageIntensityRange $img

    if { $forcebioimagesuitecoordinates  > 0 }  {
    	$imageheader ForceHeaderToBioImageSuiteCoordinatesAndFlipImage $img 
    }


    set txt "Original DICOM Series (num dicom images=[ llength $sortimglist ])\n"
    for { set i 0 } { $i < [ llength $sortimglist ] } { incr i } {
	#	puts stdout "$i [ lindex $sortimglist $i ]"
	append txt "[ file tail [ lindex [ lindex $sortimglist $i ] 0 ]] \t pos=[ lindex [ lindex $sortimglist $i ] 1 ], ori = [ lindex [ lindex $sortimglist $i ] 2 ] [ lindex [ lindex $sortimglist $i ] 3 ] [ lindex [ lindex $sortimglist $i ] 4 ] \t t= [ lindex [ lindex $sortimglist $i ] 4 ]\n"
    }

    if { $dwimode > 0 } {
	append txt "DWI Directions\n"
	if { [ llength $alldirections ]  !=1  } {
	    set mind 1
	    set maxd [ expr [ llength $alldirections ] -1 ]
	} else {
	    set mind 0
	    set maxd 1
	}
	append txt "$maxd \n"
	for { set i $mind } { $i < [ llength $alldirections ] } { incr i } {
	    set el [ split [ lindex $alldirections $i ] "," ]
	    append txt "[ lindex $el 1 ] [ lindex $el 2 ] [ lindex $el 3 ]\n"
	}
	append txt "DWI B-Values\n"
	for { set i 0 } { $i < [ llength $alldirections ] } { incr i } {
	    set el [ split [ lindex $alldirections $i ] "," ]
	    if { $i !=0 } { append txt ", " }
	    append txt "[ lindex $el 4 ]"
	}
	append txt "\n"
    }
    $imageheader AddComment $txt

    $sar Delete
    set pid [ $ana GetPatientID ]
    set pst [ $ana GetStudy]
    set pse [ $ana GetSeries ]
    set pdt [ $ana GetDate ]
    if { $pse == "" } {
	set pse 0
    }
    $ana Delete
    
    if { $pst != "1" } {
	set outname2 [ format "%s_s%03d_s_%s" $pid $pse $pst  $pdt  ]
    } else {
	set outname2 [ format "%s_s%03d_%s" $pid $pse $pdt  ]
    }
    
    if { [ GetImageSize ] < 1 } {
	Clear
	return 0
    }
    
    if { $mosaic != 0 } {
	append outname2 "_fmri"
    } elseif { $dwimode !=0 }  {
	append outname2 "_dwi"
    }
    
    set filename  "${outname2}.nii.gz"


    return 1
}
# ----------------------------------------------------------
itcl::body pxitclimage::ISPETDICOM { fname } { 

    set tname [ file tail $fname ]
    set dname [ file dirname $fname ]
    
    set nameparts [ split $tname . ]
    if { [ llength $nameparts ] != 3  } {
	return 0
    }
    set first [ lindex $nameparts 0 ]
    set last  [ lindex $nameparts 2 ]
    
    if { $first != "Image" || $last != "dcm" } {
	return 0
    }
    
    set midlist [ split [ lindex $nameparts 1 ] _ ]
    
    set tmplist [ glob [ file join $dname  "${first}.*_[lindex $midlist 1 ].${last}" ] ]
    return $tmplist 
}
# ----------------------------------------------------------
itcl::body pxitclimage::CreateLookupTable { } {

    global pxtcl_pref_array

    set robust 0
    catch { 
	if { $pxtcl_pref_array(NormalizeAnatomical) > 0 } {
	    set robust 1
	}
    }

    if { $lookuptable == 0 } {
	set lookuptable [ vtkLookupTable [ pxvtable::vnewobj ]]
    }
    
    set cutil [ vtkpxColorMapUtil [ pxvtable::vnewobj ] ]
#    puts stderr "Creating robust =$robust Lookup Table"
    $cutil SetAutoStepColorMap $img $lookuptable $robust 256 0
    $cutil Delete
}


itcl::body pxitclimage::LoadLookupTable { name } {

    if { $lookuptable == 0 } {
	set lookuptable [ vtkLookupTable [ pxvtable::vnewobj ]]
    }

    set cutil [ vtkpxColorMapUtil [ pxvtable::vnewobj ] ]
    set ok [ $cutil LoadColormap $lookuptable $name ]
    if { $ok == 0 } {
	catch { $lookuptable Delete }
	set lookuptable 0
    }
    $cutil Delete

#    puts stderr "Loading Lookup Table from $name $ok"

}
# ----------------------------------------------------------
itcl::body pxitclimage::SetLookupTable { cmap }  {

    if { $cmap == 0 } {
	if { $lookuptable != 0 } {
	    catch { $lookuptable Delete }
	    set lookuptable 0
	}
	return
    }
    
    if { $lookuptable == 0 } {
	set lookuptable [ vtkLookupTable [ pxvtable::vnewobj ]]
    }

    #    puts -nonewline stderr "pxitclimage copying lookuptable ..."
    $lookuptable DeepCopy $cmap 
    #puts stderr "done\n"
}

itcl::body pxitclimage::SaveLookupTable { name } {

    if { $lookuptable == 0 } {
	return
    }

    set cutil [ vtkpxColorMapUtil [ pxvtable::vnewobj ] ]
    set ok [ $cutil SaveColormap $lookuptable $name ]
    $cutil Delete
    #    puts stderr "Saviing Lookup Table to $name $ok"
}
# ----------------------------------------------------------

itcl::body pxitclimage::Save { args } {

    global pxtcl_pref_array

    set len [ llength $args ]
    if { $len < 1 } {
	set fname $filename
    } else  { 
	set fname [ lindex $args 0 ] 
    }

    set desc "Image"
    if { $len > 1 } { 
	set desc [ lindex $args 1 ]
    }

    set parobj 0;   if { $len > 2 } {	set parobj   [ lindex $args 2 ]  }
    set forceimageformat 0; 
    if { $len > 3 } {  
	set forceimageformat [ lindex $args 3 ]  
    } else {
	set forceimageformat $forceoutputformat 
    }
    #    puts stderr "Forceoutput =  $forceoutputformat (pxitclimage)"

    if { [ string length $fname ] == 0 } {
	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set typelist  [ ::pxitclimage::GetImageTypeList save ]

	set d [ [ $this GetImage ] GetDimensions ]

	if { [ lindex $d 2 ] == 1 } {
	    lappend typelist {"PNG Files" {.png}}
	}
	set fname  [tk_getSaveFile -title "Saving $desc" -filetypes $typelist -initialfile $f2tail -initialdir $f2path ]   
    }

    if { [ string length $fname ] <1 } { return 0   }

    set f $fname
    set ext [ file extension $f ]
    set line ""

    set status 1

    if { $ext == ".mnc" } {
	$this configure -filename $f
	set vtkwriter [ vtkMINC2ImageWriter [ pxvtable::vnewobj ] ]
	$vtkwriter SetFileName    $f
	$vtkwriter SetInput       [ $this GetImage ] 
    } elseif { $ext == ".png" } {
	$this configure -filename $f
	set vtkwriter [ vtkPNGWriter [ pxvtable::vnewobj ] ]
	$vtkwriter SetFileName    $f
	$vtkwriter SetInput       [ $this GetImage ] 
    } elseif { $ext == ".vt" } {
	$this configure -filename $f
	set vtkwriter [ vtkStructuredPointsWriter [ pxvtable::vnewobj ] ]
	$vtkwriter SetFileTypeToBinary
	$vtkwriter SetFileName    $f
	$vtkwriter SetInput       [ $this GetImage ] 
    } {
	$this configure -filename $f
	set vtkwriter [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ] ]
	$vtkwriter SetByteSwap    0
	$vtkwriter SetInput       [ $this GetImage ] 
	$vtkwriter SetImageHeader $imageheader

	set md [ $vtkwriter GetForceOutputFileFormat ]
	#puts stderr "Getting Force Format $md"
	$vtkwriter SetForceOutputFileFormat 0

	#	puts stderr "What is forceoutputformat ?  $forceimageformat"
	if { $forceimageformat == 1 } {
	    [ $vtkwriter GetImageHeader ] SetModeToAnalyze
	    if { $ext == ".gz" } {
		set f [ file root $f ]
	    }
	    if { $ext == ".nii" } {
		set f [ file root $f ]_nii
	    }
	    #puts stderr "Making Header to Analyze .... $f"
	    $vtkwriter SetForceOutputFileFormat 1
	} elseif { $forceimageformat == 2 && [ $imageheader GetMode ] == 0 } {
	    [ $vtkwriter GetImageHeader ]  SetModeToNIFTI_NII
	    $vtkwriter SetForceOutputFileFormat 2
	    #puts stderr "Making Header to NIFTI (HDR/IMG) .... $f"
	} else {
	    #puts stderr "No Force\n"
	}
		  

	$vtkwriter SetFileName    $f

	if { $ext == ".gz" } {
	    $vtkwriter SetCompression 9
	    set line "Compressed"
	} 	    
	if {  $pxtcl_pref_array(ImageColormaps) == 1 } {
	    set cname "[ file root $fname ].cmap"
	    $this SaveLookupTable $cname
	}
    }
    if { $parobj !=0 } {
	$parobj SetFilterCallbacks $vtkwriter "Saving ${line} Image"
	$parobj WatchOn 
    }
    $vtkwriter Write
    
    if { [ $vtkwriter IsA "vtkpxAnalyzeImageWriter"  ] == 1 } {
	$vtkwriter SetForceOutputFileFormat $md
    }

    catch { set status [ $vtkwriter GetSaveStatus ] }

    if { $parobj !=0 } { $parobj WatchOff  }
    
    if { $status == 0 } {
	::pxtclutil::Warning "Failed to save image $f"
    } else {
	#	puts stderr "Copying Header"
	if { [ $vtkwriter IsA "vtkpxAnalyzeImageWriter"  ] == 1 } {
	    $imageheader CopyHeader [ $vtkwriter GetImageHeader ]
	    $this configure -filename [ $imageheader GetFileName ]
	}
    }

    catch { $vtkwriter Delete }

    return $status
}
# ----------------------------------------------------------
itcl::body pxitclimage::FlipImage { mode } {
    
    if { $mode == "None" } { 
	return 1  
    }
    
    if { [ GetImageSize ] < 2 } {  
	return 0 
    }

    set reslice  [  vtkbisImageReslice [ pxvtable::vnewobj ] ]
   
    $reslice SetInput  [ $this GetImage ] 

    set trans  [  vtkTransform [ pxvtable::vnewobj ] ]
    $trans Identity
    $trans PostMultiply
    set tmat  [  vtkMatrix4x4 [ pxvtable::vnewobj ]  ]
    $tmat Identity
    
    set spa [ [ $this GetImage ] GetSpacing ]
    set ori [ [ $this GetImage ] GetOrigin ]
    set dim [ [ $this GetImage ] GetDimensions ]
    set perm(0) 0 ;  set perm(1) 1 ;  set perm(2) 2 	
    

    # Compute Transformation
    # ----------------------
    switch -exact $mode {
	"Slice Order(Z)" {
	    $tmat SetElement 2 2 -1
	    $trans SetMatrix $tmat
	}

	"Z" {
	    $tmat SetElement 2 2 -1
	    $trans SetMatrix $tmat
	}
	
	"Y" {
	    $tmat SetElement 1 1 -1
	    $trans SetMatrix $tmat
	}

	"YZ" {
	    $tmat SetElement 1 1 -1
	    $tmat SetElement 2 2 -1
	    $trans SetMatrix $tmat
	}
	
	"X" {
	    $tmat SetElement 0 0 -1
	    $trans SetMatrix $tmat
	}
	
	"Transpose" {
	    $tmat SetElement 0 0 0 ; $tmat SetElement 0 1 1 ;
	    $tmat SetElement 1 0 1 ; $tmat SetElement 1 1 0;
	    set perm(0) 1 ; set perm(1) 0 ; set perm(2) 2
	    $trans SetMatrix $tmat
	}
	
	"FlipTranspose" {
	    $tmat SetElement 0 0 0 ;  $tmat SetElement 0 1 -1 ;
	    $tmat SetElement 1 0 -1 ; $tmat SetElement 1 1 0;
	    $trans SetMatrix $tmat
	    set perm(0) 1 ; set perm(1) 0 ; set perm(2) 2
	}
	
    }
    catch {$tmat Delete }
    
    $reslice SetResliceTransform $trans
    $reslice AutoCropOutputOn

    for { set k 0 } { $k <=2 } { incr k } {
	set outsp($k)  [ lindex $spa $perm($k) ]
    }
    $reslice SetOutputSpacing $outsp(0) $outsp(1) $outsp(2)

    set wd [ expr int( [ lindex $dim 0 ]*[lindex $spa 0 ]/ $outsp(0)) - 1]
    set ht [ expr int( [ lindex $dim 1 ]*[lindex $spa 1 ]/ $outsp(1)) - 1]
    set dp [ expr int( [ lindex $dim 2 ]*[lindex $spa 2 ]/ $outsp(2)) - 1]
    $reslice SetOutputExtent 0 $wd 0 $ht 0 $dp

    catch { unset outsp }
    $reslice SetInterpolationMode 0
    $reslice SetBackgroundLevel 0
    $reslice Update
    [ $reslice GetOutput ] SetOrigin 0 0 0 
    $this ShallowCopyImage [ $reslice GetOutput ]
    catch { $reslice Delete }
}

# --------------------------------------------------------------------------------------------------
itcl::body pxitclimage::LoadVarian { fname { parobj 0 } { flipdti 0 } } {


    set lastdicomlist ""
    set baseelement [ ::pxtclreadvarianheader::ReadVarianHeader $fname ]
    if { $baseelement ==0 } {
	return 0
    }

    
    set tmpname  [ file root [ file tail [ file dirname [ file normalize $fname ] ] ] ]
    puts stdout "Filename = $tmpname"

    set studyid [ $baseelement GetAttribute "studyid"  ]

    # Single Image ..........
    if { $studyid == "__none__" } {
	set tmpname2  [ file tail $fname ] 
	[ $this GetImageHeader ] CreateVarianHeader $baseelement
	set tmpimg [ ::pxtclreadvarianheader::ReadVarianImage $baseelement $parobj ]
	$this ShallowCopyImage $tmpimg
	$tmpimg Delete
	$this configure -filename ${tmpname}_${tmpname2}
	$baseelement Delete
	set lastdicomlist $fname
	return 1
    }


    set dname [ file normalize [ file dirname $fname ] ]
    set fnamelist ""
    catch { set fnamelist [ lsort [ glob [ file join $dname *.fdf ]] ] }
    if  { $fnamelist == "" } {
	return 0
    }
    set fnamelist [ lsort -unique [ concat [ file normalize $fname ] $fnamelist ] ]


    set imglist  ""
    set found 0
    set mosaic 0
    set dwimode 0
    set numslices [ $baseelement GetAttribute "slices" ]
    set numframes [ $baseelement GetAttribute "array_dim" ]
    set numechos [ $baseelement GetAttribute "echoes" ]
    set dointerleave 0
    set dwidirlist ""

    set gd [ $baseelement GetAttribute "Gdiff1" ]
    if { $gd != "" } {
	set dwimode 1
	set dwidirlist "[ $baseelement GetAttribute "Gdiff1" ],[ $baseelement GetAttribute "Gdiff2" ],[ $baseelement GetAttribute "Gdiff3" ]"
    }
    
    
    set n [ llength $fnamelist ]

    for { set i 0 } { $i < $n  } { incr i } {
	set testname [ lindex $fnamelist $i ]
	set r [ ::pxtclreadvarianheader::ReadVarianHeader $testname ]
	if { $r !=0 } {
	    set sid [ $r GetAttribute "studyid" ]
	    if { $sid == $studyid } {
		if { $dwimode == 1 } {
		    set lst "[ $r GetAttribute "Gdiff1" ],[ $r GetAttribute "Gdiff2" ],[ $r GetAttribute "Gdiff3" ]"
		} else {
		    set lst "0,0,0"
		}
		set sliceno [ $r GetAttribute "slice_no" ]
		set frameno [ $r GetAttribute "array_index" ]
		set location [ $r GetAttribute "location" ]

		for { set j 0 } { $j <=2 } { incr j } {
		    set spa($j) [ $r GetAttribute "bis_Spacing$j" ]
		    set dim($j) [ $r GetAttribute "bis_Dimension$j" ]
		    set bits    [ $r GetAttribute "bits" ]
		    set hd      [ $r GetAttribute "bis_HeaderSize" ]
		}
		lappend imglist [ list $testname "[ $r GetAttribute "display_order" ]" "$sliceno" "$frameno" "$lst" [ list $dim(0) $dim(1) $dim(2)  $spa(0) $spa(1) $spa(2) $bits $hd ] "$location" ]
	    }
	    $r Delete
	}
    }

    if { [ llength $imglist ] == 0 } {
	return 0
    }

    set sortimglist [ lsort -real -increasing -index 1 $imglist ]

    set dwidirlist ""
    for { set i 0 } { $i < [ llength $sortimglist ] } { incr i } {
	set el [ lindex $sortimglist $i ]
	if { $dwimode > 0 } {
	    set slno [ lindex $el  2]
	    if { $slno == 1 } {
		lappend dwidirlist [ lindex $el 4 ]
	    }
	}
    }
	
    if { $dwimode > 0 } {
	for { set i 0 } { $i < [ llength $dwidirlist ] } { incr i } {
	    puts stdout "dwi $i = [ lindex $dwidirlist $i ]"
	}
    }

    if { [ llength $sortimglist ] > 1 && $numslices > 1 } {
	set upper 0
	set el1 [ lindex $sortimglist 0 ]
	set loc1 [ lindex $el1 6 ]
	set zdim 0.0

	while { $upper < [ llength $sortimglist ] && $zdim == 0.0 } {
	    incr upper
	    set el2 [ lindex $sortimglist $upper ]
	    set loc2 [ lindex $el2 6 ]
	    set sum 0.0
	    for { set i 0 } { $i<=2 } { incr i } {
		set x1 [ lindex $loc1 $i ]
		set x2 [ lindex $loc2 $i ]
		set sum [ expr $sum+($x1-$x2)*($x1-$x2) ]
	    }
	    set sum [ expr sqrt($sum) ]
	    set zdim $sum
	    #	    puts stdout "zdim=$zdim, upper=$upper slices=$numslices, $numechos"
	}
	set units [ $baseelement GetAttribute "abscissa" ]
	if { $upper >= 2 } {
	    set numslices $numechos
	    set dointerleave 1
	}


	#	puts stderr "units=$units\n\n\n\n"
	if { [ llength $units ] > 0 } {
	    if { [ lindex $units 0 ] == "cm" } {
		set zdim [ expr 10.0*$zdim ]
	    }
	}
    } else {
	set zdim -1.0
    }

    #    puts stderr "zdim=$zdim"
    if { $zdim > 0.0 } {
	$baseelement SetAttribute "bis_Spacing2" $zdim 
    }

    set appnd [ vtkImageAppend New ]
    $appnd  SetAppendAxis 2
    for { set i 0 } { $i < [ llength $sortimglist ] } { incr i } {
	set anar [ vtkpxAnalyzeImageSourceOld New ]
	set el [ lindex $sortimglist $i ]
	set dt [ lindex $el 5 ]
	set fn [ lindex $el 0 ]
	set loc [ lindex $el 6 ]

	if { $zdim < 0.0 } {
	    $anar SetVoxelDimensions [ lindex $dt 3 ] [ lindex $dt 4 ] [ lindex $dt 5 ]
	} else {
	    $anar SetVoxelDimensions [ lindex $dt 3 ] [ lindex $dt 4 ] $zdim
	}
	$anar SetHeaderInfo [ lindex $dt 0 ] [ lindex $dt 1 ] [ lindex $dt 2 ] 1 0 [ expr [ lindex $dt 6 ] / 8 ]
	$anar SetHeaderSize [ lindex $dt 7 ]
	$anar SetFilePrefix $fn
	lappend lastdicomlist $fn
	if { $parobj !=0 } { $parobj SetFilterCallbacks $anar "Reading Varian Image [ lindex $el 2]/[lindex $el 3]" }
	#	puts stdout "Reading Varian Image slice:[ lindex $el 2] frame:[lindex $el 3] ($loc, $zdim) from $fn"
	$anar Update
	$appnd AddInput [ $anar GetOutput ]
	$anar Delete
    }
    $appnd Update

    set co [ vtkpxImageComponentsToFrames [ pxvtable::vnewobj ]]
    $co SetSlicesPerFrame $numslices
    $co SetInverse 1
    $co SetInput [ $appnd GetOutput ] 
    $co Update

    set tmpimage 0


    if { $dointerleave } {
	set tmpimage [ vtkImageData New ]
	set ut [ vtkpxUtil New ]
	$ut ReorderImage $tmpimage [ $co GetOutput ] 
	set imgtocopy $tmpimage
	puts stdout "Auto interleaving image"
	$ut Delete
    } else {
	set imgtocopy [ $co GetOutput ]
    }

    if { $flipdti > 0 && $dwimode > 0 } {
	set flipx [ vtkImageFlip New ]
	$flipx SetInput $imgtocopy
	$flipx SetFilteredAxis 0
	$flipx Update

	if { $tmpimage == 0 } {
	    set tmpimage [ vtkImageData New ]
	}
	$tmpimage ShallowCopy [ $flipx GetOutput ]
	set imgtocopy $tmpimage
	$flipx Delete
	puts stdout "Flipping DWI Image along x-axis to correct for bug"
    }
	

    set vl [ ::pxtclreadvarianheader::GetVarianScaleFactor [ $co GetOutput ] ]
    if {  $vl > 1.0 } {
	set sscale [ vtkImageShiftScale New ]
	puts stdout "Scaling 4D Varian Image by $vl"
	$sscale SetShift 0.0
	$sscale SetScale $vl
	$sscale SetInput $imgtocopy
	$sscale Update
	$this ShallowCopyImage [ $sscale GetOutput ]
	$sscale Delete
    } else {
	$this ShallowCopyImage $imgtocopy
    }




    [ $this GetImageHeader ] CreateVarianHeader $baseelement

    $this configure -filename "${studyid}.nii.gz"

    $co Delete
    $appnd Delete

    if { $tmpimage !=0 } {
	$tmpimage Delete
    }

    set txt "\#Original Header Info"
    set n [ $baseelement GetNumberOfAttributes ]
    for { set  i 0 } { $i < $n } { incr i } {
	set a [ $baseelement GetAttributeName $i ]
	set b [ $baseelement GetAttributeValue $i ]
	if { [ string first "bis_" $a ] !=0 } {
	    append txt "$a = $b\n"
	}
    }

    append txt "--------------------------------------\nOriginal Image Info\n"
    for { set i 0 } { $i < [ llength $sortimglist ] } { incr i } {
	append txt "Image [ expr $i+1]: [ lindex $sortimglist $i ]\n"
    }

    if { $dwimode > 0 } {
	append txt "--------------------------------------\nDWI Directions\n"
	append txt "[ expr [ llength $dwidirlist ] -1 ]\n"
	for { set i 1 } { $i < [ llength $dwidirlist ] } { incr i } {
	    append txt "[ lindex $dwidirlist $i ] \n"
	}
	append txt "\n"
    }
    $imageheader AddComment $txt
    #    puts stdout "txt=$txt\n[ $this GetOrientation ], [ $this GetDescription]"
    $baseelement Delete
    $this configure -filename $tmpname


    

    return 1
}
# ----------------------------------------------------------------------------------


itcl::body pxitclimage::CompareTo  { fname { thr 0.001 } } {

    set tmp [ pxitclimage \#auto ]
    set ok [$tmp Load $fname  ]
    if { $ok == 0 } {
	itcl::delete object $tmp
	return 0
    }

    set ut [ vtkbisTestUtil New ]
    $ut ClearStatus
    set ok [ $ut CompareImages [ $this GetImage ] [ $tmp GetImage ] $thr ]
    itcl::delete object $tmp
    set a [ $ut ReturnStatus ]
    $ut Delete
    return [ list $ok $a ]
}

itcl::body pxitclimage::CompareTo  { fname { thr 0.001 } } {

    set tmp [ pxitclimage \#auto ]
    set ok [$tmp Load $fname  ]
    if { $ok == 0 } {
	itcl::delete object $tmp
	return 0
    }

    set ut [ vtkbisTestUtil New ]
    $ut ClearStatus
    set ok [ $ut CompareImages [ $this GetImage ] [ $tmp GetImage ] $thr ]
    set a [ $ut ReturnStatus ]
    itcl::delete object $tmp
    $ut Delete
    return [ list $ok $a ]
}

itcl::body pxitclimage::CorrelateWith  { fname { thr 0.9 } } {

    set tmp [ pxitclimage \#auto ]
    set ok [$tmp Load $fname  ]
    if { $ok == 0 } {
	itcl::delete object $tmp
	return 0
    }

    if { $thr < 0.05 } {
	set thr [ expr 1.0 - $thr ]
	if { $thr > 1.0 } {
	    set thr 1.0
	}
    }

    set ut [ vtkbisTestUtil New ]
    $ut ClearStatus
    set ok [ $ut CorrelateImages [ $this GetImage ] [ $tmp GetImage ] $thr ]
    set a [ $ut ReturnStatus ]
    itcl::delete object $tmp
    $ut Delete
    return [ list $ok $a ]
}

# ----------------------------------------------------------
#  GUI for pxitclimage
# ----------------------------------------------------------
itcl::class pxitclimageGUI {

    inherit pxitclobjectGUI

    public variable browsebutton

    constructor { } {
	pxitclobjectGUI::constructor
    } { 
	set thisparam($this,status) "vtkImageData"
	set thisparam($this,shortfilename) "none"
	set thisparam($this,descriptionbox) 0
	Reset
    }

    destructor { }


    public method SetObject { tr } { return [ SetImage $tr ] }
    public    method GetImage { } { return $itclobject  }

    protected method CreateNewObject { } 
    public    method Initialize { basewidg } 
    public    method SetImage { img }
    public    method BrowseImage { } h


}
# ----------------------------------------------------------
itcl::body pxitclimageGUI::CreateNewObject { } {
    set itclobject  [ [  pxitclimage \#auto ] GetThisPointer ]
}

itcl::body pxitclimageGUI::BrowseImage { } {
    $itclobject Browse $description
    Update
}

itcl::body pxitclimageGUI::SetImage { trn } {
    
    if { [ $trn isa pxitclimage ] == 0 } {
	return 0
    }
	
    if { $owns_object == 1} {
	catch { itcl::delete object $itclobject }
    }

    set itclobject $trn
    set owns_object 0
    Update
}

itcl::body pxitclimageGUI::BrowseImage { } {
    $itclobject Browse $description
    Update
}

itcl::body pxitclimageGUI::Initialize { basewidg } {

    if { $initialized == 1 } { return $basewidget }
    pxitclobjectGUI::Initialize $basewidg
    
    set browsebutton [ eval "button $buttonbar.b -text Browse -command { $this BrowseImage }" ]
    pack  $buttonbar.b   -side left -fill x -expand f

    Update
    return $basewidget
}

# ----------------------------------------------------------
#  GUI for multiple image object
# ----------------------------------------------------------
itcl::class pxitclmultiImageGUI {

    inherit pxitclmultiObjectGUI

    constructor { } {
	pxitclmultiObjectGUI::constructor
    } {
    }
    
    destructor { }
    
    public    method Initialize { basewidg } 

    public    method AddImage { descr }
    public    method SetImage { index } 
    public    method GetImage { index } { return [ GetObject $index ] }
    public    method DeleteImage { index } { DeleteObject $index }

    protected method CreateNewObject { }
    protected method CreateNewObjectGUI { widget }

}

# ----------------------------------------------------------
itcl::body pxitclmultiImageGUI::CreateNewObject { } {

    return  [ [  pxitclimage \#auto ] GetThisPointer ]
}

itcl::body pxitclmultiImageGUI::CreateNewObjectGUI { widget } {
    set itclimageGUI [ [ pxitclimageGUI \#auto ] GetThisPointer ]
    set w  [ $itclimageGUI InitializeLite $widget.[ pxvtable::vnewobj ] 2 ] 
    pack $w -side left -fill x
    return $itclimageGUI
}

itcl::body pxitclmultiImageGUI::AddImage { descr } {
    
    set newobj [ $this AddObject $descr ]
    $this SetImage [ expr [ llength $itclobjectlist ] -1 ]    
    return $newobj
}

itcl::body pxitclmultiImageGUI::SetImage { index } {

    $this SetObject $index
    $objectGUI configure -description [ $listbox get $currentobject ]
    $objectGUI Update
}

itcl::body pxitclmultiImageGUI::Initialize { basewidg } {
    
    if { $initialized == 1 } { 
	return $basewidget 
    }
    
    pxitclmultiObjectGUI::Initialize $basewidg

    $listbox configure -selectmode single -exportselection 0
    eval "$listbox configure -selectioncommand { $this SetImage -1 }"
    
    set initialized 1
    
    return $basewidget
}
 



