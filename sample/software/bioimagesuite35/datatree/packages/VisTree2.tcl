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

########################################################################################
########################################################################################
#				File Tree Widget Definition			       #
#			     based on Widget by D. Richard Hipp			       #
#			Modified July 2005 by Marcello DiStasio	to Version 2.0         #
########################################################################################
########################################################################################



package provide VisTree2 2.0

#A Couple preliminary formatting options for the file tree

option add *highlightThickness 0


namespace eval Tree { 

    namespace export create dfltconfig config newitem delitem setselection getselection build buildlayer open close drawselection buildwhenidle labelat

    #main Tree variable
    variable Tree

    #icon data variables
    variable fileicon
    variable diricon
    variable brainiconbw
    variable brainicongrey
    variable purplebrainicon
    variable redbrainicon
    variable orangebrainicon 
    variable yellowbrainicon 
    variable greenbrainicon 
    variable bluebrainicon 
    variable lightbluebrainicon 
    variable rainbowbrainicon 
    variable arrowicon2 
    variable arrowicon 
    variable arrowbrain
    variable cactusicon



    global tcl_platform
    switch $tcl_platform(platform) {
	unix {
	    set Tree(font) \
		-adobe-helvetica-medium-r-normal-*-12-80-100-100-p-56-iso8859-1
	}
	windows {
	    set Tree(font) \
		-adobe-helvetica-medium-r-normal-*-14-100-100-100-p-76-iso8859-1
	}
    }

    #
    # Create a new tree widget.  $args become the configuration arguments to
    # the canvas widget from which the tree is constructed.
    #
    proc create {w args} {

	variable Tree
	variable diricon
	variable brainiconbw
	variable brainicongrey
	variable purplebrainicon
	variable redbrainicon
	variable orangebrainicon 
	variable yellowbrainicon 
	variable greenbrainicon 
	variable bluebrainicon 
	variable lightbluebrainicon 
	variable rainbowbrainicon 
	variable arrowicon2 
	variable arrowicon 
	variable arrowbrain
	variable cactusicon


	eval canvas $w $args
	bind $w <Destroy> "::Tree::delitem $w /"
	Tree::dfltconfig $w /
	Tree::buildwhenidle $w
	set Tree($w:selection) {}
	set Tree($w:current) {}
	set Tree($w:selidx) {}
	set Tree($w:selidcurrent) {}
	#------------------------------------------------------------------------------------------
	# These are all the icon image definitions
	#------------------------------------------------------------------------------------------

	set diricon [image create photo idir -data {
	    R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4APj4+P///wAAAAAAACwAAAAAEAAQAAADPVi63P4w
	    LkKCtTTnUsXwQqBtAfh910UU4ugGAEucpgnLNY3Gop7folwNOBOeiEYQ0acDpp6pGAFArVqt
	    hQQAO///}
		    ]
	#lots of for loops to clean up the transparency of the folder image
	for {set i1 0} {$i1 < 3} {incr i1} {
	    for {set i2 0} {$i2 < 16} {incr i2} {
		$diricon transparency set $i2 $i1 1
	    }
	}
	for {set i3 0} {$i3 < 16} {incr i3} {
	    $diricon transparency set 15 $i3 1
	}
	for {set i4 15} {$i4 > 6} {incr i4 -1} {
	    $diricon transparency set $i4 3 1
	}
	for {set i4 15} {$i4 > 7} {incr i4 -1} {
	    $diricon transparency set $i4 4 1
	}
	#A couple more spots
	$diricon transparency set 14 5 1
	$diricon transparency set 0 15 1
	$diricon transparency set 0 3 1
	$diricon transparency set 0 4 1
	$diricon transparency set 1 3 1
	
	#Now I'll correct the file image to have a transparent bg with for loops as above
	set fileicon [image create photo ifile -data {
	    R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4+P///wAAAAAAAAAAACwAAAAAEAAQAAADPkixzPOD
	    yADrWE8qC8WN0+BZAmBq1GMOqwigXFXCrGk/cxjjr27fLtout6n9eMIYMTXsFZsogXRKJf6u
	    P0kCADv/}
		     ]
	for {set i5 0} {$i5 < 16} {incr i5} {
	    $fileicon transparency set 0 $i5 1
	    $fileicon transparency set 14 $i5 1
	    $fileicon transparency set 15 $i5 1
	}
	#And a couple more pixels in the corner...
	$fileicon transparency set 11 0 1
	$fileicon transparency set 12 0 1
	$fileicon transparency set 12 1 1
	$fileicon transparency set 13 0 1
	$fileicon transparency set 13 1 1
	$fileicon transparency set 13 2 1
	
	#Define a brain icon with hexadecimal values
	set brainiconbw [image create bitmap ibrainbw -data {
	    
	    #define smallbrain2_width 18
	    #define smallbrain2_height 16
	    static char smallbrain2_bits[] = {
		0xff,0xff,0x03,0x3f,0xf0,0x03,0x0f,0xc0,0x03,0x97,0xa4,0x03,0x07,0x11,0x03,
		0x53,0x88,0x03,0xa5,0x45,0x02,0x0b,0x94,0x02,0x93,0x88,0x02,0x2f,0x92,0x02,
		0x4f,0x24,0x03,0x57,0xd1,0x03,0x27,0xfd,0x03,0x9f,0xff,0x03,0xff,0xff,0x03,
		0xff,0xff,0x03,0x00,0x88,0x00,0x00,0x00,0x19,0x00,0x00,0x00,0x66,0x61,0x6c,
		0x73,0x65,0x00,0x67 };
	    
	} ]

	set brainicongrey [image create photo ibraingrey -data {
	    R0lGODlhEgASAOcAAP3+/f79//z//fz89/z7+/Ly8rWtu6WkpNvS0vT59/z5\
		+v77/vv+/v7+/vz+/P3+/vbz+IeHh/f/9v77/f3+9/r88sK6yvX69Pr+/P39\
		/vf596Ojo7qxwvz9+9PB2CcrJVtfWYOEhpyRo/789jo4O4+NiI2KioOBimdn\
		YOfd5tnMxIGAhnd1d2pna5WTlYKChmRoZZeXl25te5WPkXBycmVlZVRUVNXO\
		1oGDgnd3dMrLyrvAvbatwPz8+dfJ0ZCFlrCytNfT1szMzL6+vqGfoaOeosrQ\
		yIKAhf78/vr+/fv++eLc37apuMHDwuLi4s/Pz76/vq6vsL61voB9hPj7+rCx\
		sdnZ2aysrL+/v6urq2lnaubZ6vj8/Ozn8qusr8vLy83NzZqampKSkn9/f8PD\
		wvz59/77+f/8+f38//j7+fj9+Pz7+fj6+dHNz7y8vMnJyZiYmPb29v3/+/v/\
		///9+v36///7/Pr+/vz8+rCwsM7OzqampvHx8f/////+/f/+/MTExK6uruTk\
		5Onp6cLCwt7e3v//////////////////////////////////////////////\
		////////////////////////////////////////////////////////////\
		////////////////////////////////////////////////////////////\
		////////////////////////////////////////////////////////////\
		////////////////////////////////////////////////////////////\
		////////////////////////////////////////////////////////////\
		////////////////////////////////////////////////////////////\
		////////////////////////////////////////////////////////////\
		/////////////////////ywAAAAAEgASAAAI9QABBBAwgEABAwcQHFiYQMEC\
		Bg0iOngAIYJCBBgxLpQwISKFCgk1ZhRp4UJEDAlTXhypMUMDDRlDRtgQciSH\
		Dh5YIojwAUQIESMPjLBYk8SBEiZOoKCZMcVFFQhWsDjQwsULGDFGRlCZUcYM\
		GjVsMM14Q+PCnThyRIigYwePjD18xETwA0gQIUOIFDFyBCOSJEqWjGTSxMkT\
		KFGkTFEYsQGVmhGqWHlyBUsWLQe2NObS5ewBL1/AhBEzhkwZM43PoEmjZg2b\
		Nm7ebIATp4Gcxg3m0EFSx84dPHn07OHToI+fP7iTNwAEJpCgPn2UKx9EyE0h\
		3AEBADs=
	} ]

	set purplebrainicon [image create photo ibrainpurple -data {
	    R0lGODlhEgASAOcAACIiKnZ6dpqamsK6ymZmYs7OzmIqisrSymZWct7e3q5m\
		yo4+ulZKYmZGiuLi4opSpjYyNqZ6vopiqoYqvurq6lYidqKeokJGQo5SsmIy\
		ir62vpKGmvLy8jo6OppSwn5iko6KiqKiom5GitLC1p6Govb29mYyinIioop2\
		jmZqZlo2erqWyrKawsrKyqpW4nY+mn5Okn42oq6urnIymvr+8tbS1p5CzlZW\
		VoZ2hl5CZnpWhoZCro5GtnIinqKOqn5KmnJ2cnI6lrJW4oo2utK22o5uomom\
		kr6+vv7+9o6CnoKChnYqqvr6+rauwloqepJ2ptrO4uLW5qqqqrpq4oZenpaK\
		omI+dsbGxq6SuppKytLK1noymrKyspp+qno6rqZe0v7++opOqooyrloiho6O\
		imouinpejmpudpJiqm4yjraqun5+fu7m8sKu0rrCvtbO1pZCwiYqJq5q0q6C\
		wn5qitra2qJKzlpeWoo+vqJS0nIqmvb+9noypq5i2q5e2sLCwpZSwn46spZq\
		snp2fpaOkpJGvnoqtnY2ov769v7+/oYyuiomJube5no6omIugp6KrnJyfpp6\
		tvr++v76/vb69oKGhl4mho5Cwoo6tnouqm5ycno2ppKSkmZmZvby+oJ+hubm\
		5oZWno5mrp5WwqamplY6cn46qp6Sorqywuba6qqurpZmrrauum4umqpm1pJK\
		vtLOzmoykraayopCtrZW6l4qgmYuipJGsl4iimpmavr+/mYqjuLe3pI+uno+\
		nnZ2dpZ2qtbK0n5eim5uenIykooyupaSlv76+q6usnIynoKCirKyttLC2p6G\
		ppp+ropOrnoyqpJGtv//////////////////////////////////////////\
		////////////////////////////////////////////////////////////\
		////////////////////////////////////////////////////////////\
		/////////////////////yH5BAEKAP8ALAAAAAASABIAAAj+ABMJRHKMAysf\
		kYAlGUHp2CRdAgXq8sQCzbM0s774cqVDy55JAmnQiBKhFqYpYTYNWSIkz4MB\
		lCRCcQSnlx8jFUxNyMRDjwcnjwRSWgVogalWKuh0eSIhSBYFW1yhAsPMRTFL\
		m8wMuxDnTqVTInyNsVEEEQtMXxzNQtBhERkQygig4IOrlwlGguyk8TLjDAQA\
		uTgpIcBgE49Yr9pEonXiS6YxVoYRGkbgBiRhGQwswfImSJ9bMxTNwhEAyK8A\
		Bdyo+eFhzrFgzhok41MqCZcaBY5YsHDg048ViXQhSRXDVA4Dav44yM1FwydR\
		RASCoUSlxxBFj2TUOSDliJRcwlJFRWTChkoZDBtktGghwNiaP0wQRUTEZA8N\
		MExgHWkRQkAJMGBEFFwikzDx0CQyFEAKBwI22OAfBcgAioMUJkLBHxokIGBA\
		ADs=
	}]

	set redbrainicon [image create photo ibrainred -data {
	    R0lGODlhEgASAOcAAP3+/f79//z//fz89/z7+/Ly8rWtu8kAAOgSC/T59/z5\
		+v77/vv+/v7+/vz+/P3+/vbz+LKawvQHB/f/9v77/f3+9/r88sK6yvX69Pr+\
		/P39/vf597qxwvz9+9PB2Id9dkBEQScrJVtfWYOEhuhMJ/789mRXcTo4Oykm\
		JY+NiI2KioOBimdnYOfd5mtsdDQwNCIiKmpna5WTlYKChmRoZVRIYsOu0G5t\
		e5WPkW9xcWVlZVRUVHp2fXxgktXO1oV1hXR5d3N0cHZ2dnx8fMrLyrvAvbat\
		wPz8+dfJ0ZOFmrCytNfT1szMzL6+vqGfoaOeosrQyIKAhf78/vr+/fv++eLc\
		37apuMHDwuLi4s/Pz76/vq6vsL61voB9hPj7+p6Ho7CxsdnZ2aysrL+/v6ur\
		q2lnaubZ6vj8/Ozn8qusr8vLy83NzZqampKSkn9/f8PDwvz59/77+f/8+f38\
		//j7+fj9+Pz7+fj6+dHNz7y8vMnJyaOjo5iYmPb29v3/+/v////9+v36///7\
		/Pr+/vz8+rCwsM7OzqampvHx8f/////+/f/+/MTExK6uruTk5Onp6cLCwt7e\
		3skAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkA\
		AMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkA\
		AMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkA\
		AMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkA\
		AMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkA\
		AMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkA\
		AMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkAAMkA\
		AMkAAMkAAMkAAMkAAMkAACH5BAEKAP8ALAAAAAASABIAAAj3AAEEEDCAQAED\
		BxAcWJhAwQIGDSI6eAAhggQEGDNinEAhYgULCTWKRHABQ8QMCxOGDIlRpYYG\
		GzKqTLlQJocOHmQe+AAihIgRKxGQKNFSoYkTKFKoWMEiJcYWLRe6eAEjhowZ\
		NGqwtFE05Q0cOXTs4NGDpQ+FK38ACSJkCJEiRloeQTITQRIlS5g0cfIEShSM\
		UqZQqcLSyhUsWbRs4dJlYcQGXlh+ARMmi5gxZMpIMPP4DJqaB9KoWcOmjZs3\
		cOI8ljOHTh07d/Dk0bOHT58Gfh43+ANISiBBgwgVMnQIUYNEihbpXt6A0ZpG\
		jhIlYs78EaQ8kXQHBAA7
	}]
	
	set orangebrainicon [image create photo ibrainorange -data {
	    R0lGODlhEgASAOcAAP3+/f79//z//fz89/z7+/Ly8rWtu85/JeuqQb9lEfT5\
		9/z5+v77/vv+/v7+/vz+/P3+/vbz+LKawv+yQf/DZeOlQf+6Wff/9v77/f3+\
		9/r88vmuQcK6yvX69Pr+/P39/vf59/S5bH5oipyFp8SQd7qxwvz9+9PB2OWo\
		Y4d9dkBEQScrJVtfWYOEhpyRo+mlU/789rWayOGuXmRXcTo4OykmJY+NiI2K\
		ioOBimdnYIp1jufd5tGaQeGgQWtsdDQwNCIiKmpna5WTlYKChmRoZVRIYsOu\
		0NaheuGqaG5te5WPkW9xcWVlZVRUVHp2fXxgktXO1oV1hXR5d3N0cHZ2dnx8\
		fMrLyrvAvbatwOmrdfz8+dfJ0ey2cpOFmrCytNfT1szMzL6+vqGfoaOeosrQ\
		yIKAhf78/vr+/fv++eLc37apuMHDwuLi4s/Pz76/vq6vsL61voB9hPj7+p6H\
		o7CxsdnZ2aysrL+/v6urq2lnaubZ6vj8/Ozn8qusr8vLy83NzZqampKSkn9/\
		f8PDwvz59/77+f/8+f38//j7+fj9+Pz7+fj6+dHNz7y8vMnJyaOjo5iYmPb2\
		9v3/+/v////9+v36///7/Pr+/vz8+rCwsM7OzqampvHx8f/////+/f/+/MTE\
		xK6uruTk5Onp6cLCwt7e3m03BW03BW03BW03BW03BW03BW03BW03BW03BW03\
		BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03\
		BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03\
		BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03\
		BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03\
		BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03BW03\
		BW03BW03BW03BW03BW03BSH5BAEKAP8ALAAAAAASABIAAAj+AAEEEDCAQAED\
		BxAkWKhgAYMGDiI+gBBBwoQEFCpMmGBh4QUMETNoSGChJEYEGzhi5NAhogeM\
		JA90PJASpsIPDkCEoKCwpIgRJDhS4JmghIkTQxFYQJFCxQoWLVwMTTDhBYwY\
		MhJOmEGjho0bOHLoSIBg446OMnj08PEDSBAhQ4gU4bnRyBEKZDkiSaJkCZMm\
		Tp6U5Qhl6kIKUaRMoVLFyhUsHLNo2cKl7AEKXbx8ARNGzBgyZUqaOYMmjVAE\
		atawaePmDZw4HSM6kEOS5xw6ddrYuYMnTwI9svfwWaiwj58/gAIJGkSokGxD\
		hxAlUrSIUSNHjyBFciBJtoNJlMwhVLJ0CVMmTZs4Oejk6ZP39w5A/QklqlMn\
		+PBHkWpUyntAADs=
	}]

	set yellowbrainicon [image create photo ibrainyellow -data {
	    
	    R0lGODlhEgASAOcAAP3+/f79//z//fz89/z7+/Ly8rWtuxuZFv/yAPT59/z5\
		+v77/vv+/v7+/vz+/P3+/vbz+LKawvf/9v77/f3+9/r88sK6yvX69Pr+/P39\
		/vf59wf0I7qxwvz9+9PB2Id9dkBEQScrJVtfWYOEhv789mRXcTo4OykmJY+N\
		iI2KioOBimdnYOfd5mtsdDQwNCIiKmpna5WTlYKChmRoZVRIYsOu0G5te5WP\
		kW9xcWVlZVRUVHp2fXxgktXO1oV1hXR5d3N0cHZ2dnx8fMrLyrvAvbatwPz8\
		+dfJ0ZOFmrCytNfT1szMzL6+vqGfoaOeosrQyIKAhf78/vr+/fv++eLc37ap\
		uMHDwuLi4s/Pz76/vq6vsL61voB9hPj7+p6Ho7CxsdnZ2aysrL+/v6urq2ln\
		aubZ6vj8/Ozn8qusr8vLy83NzZqampKSkn9/f8PDwvz59/77+f/8+f38//j7\
		+fj9+Pz7+fj6+dHNz7y8vMnJyaOjo5iYmPb29v3/+/v////9+v36///7/Pr+\
		/vz8+rCwsM7OzqampvHx8f/////+/f/+/MTExK6uruTk5Onp6cLCwt7e3gOq\
		EQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOq\
		EQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOq\
		EQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOq\
		EQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOq\
		EQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOq\
		EQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOq\
		EQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOqEQOq\
		EQOqEQOqEQOqEQOqEQOqESH5BAEKAP8ALAAAAAASABIAAAjuAAEEEDCAQIED\
		BxAgPJBAwQIGDSI6eABhIYKLGA9ImBCRQgWEGENitHAhIoaEIlFeTHggQwMN\
		IDNazMihg0qEH0CEEDECJUoSKhGUMHECRQoVK2ayuNnCxQsYMWTMoKGyBkuf\
		Nm7gyKFjBw+VPYIi8PEDSBAhQ4gUWWkEJEgkSZQsYdLEyRMoF6NImUIlZBUr\
		V7Bk0bKFC8KIDbqo9PIFDJYwYsaQ2VAGsZkzbtGkUbOGTRs3b+AgjiNnDp06\
		du7gyaNnD58GfRA38PMnCqBAggYRKmToUANEiRTJHt5gkRpGjRAhIk7c0SM8\
		kGQHBAA7
	}]

	set greenbrainicon [image create photo ibraingreen -data {

	    R0lGODlhEgASAOcAAP3+/f79//z//fz89/z7+/Ly8rWtuxuZFgf0I/T59/z5\
		+v77/vv+/v7+/vz+/P3+/vbz+LKawvf/9v77/f3+9/r88sK6yvX69Pr+/P39\
		/vf597qxwvz9+9PB2Id9dkBEQScrJVtfWYOEhv789mRXcTo4OykmJY+NiI2K\
		ioOBimdnYOfd5mtsdDQwNCIiKmpna5WTlYKChmRoZVRIYsOu0G5te5WPkW9x\
		cWVlZVRUVHp2fXxgktXO1oV1hXR5d3N0cHZ2dnx8fMrLyrvAvbatwPz8+dfJ\
		0ZOFmrCytNfT1szMzL6+vqGfoaOeosrQyIKAhf78/vr+/fv++eLc37apuMHD\
		wuLi4s/Pz76/vq6vsL61voB9hPj7+p6Ho7CxsdnZ2aysrL+/v6urq2lnaubZ\
		6vj8/Ozn8qusr8vLy83NzZqampKSkn9/f8PDwvz59/77+f/8+f38//j7+fj9\
		+Pz7+fj6+dHNz7y8vMnJyaOjo5iYmPb29v3/+/v////9+v36///7/Pr+/vz8\
		+rCwsM7OzqampvHx8f/////+/f/+/MTExK6uruTk5Onp6cLCwt7e3gf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0IyH5BAEKAP8ALAAAAAASABIAAAj1AAEEEDCAQAED\
		BxAcWJhAwQIGDSI6eAAhAoKLGDFKmBCRQoWEGUMisHAhIoaFCUGCvJgyQwMN\
		GFOiXBhzA4cOMQ94+AAihAiVF0ewVEiihIkTKFKoQHlxBcuFLFq4eAEjhowZ\
		K2kMRVnDxg0cOXTsWMlDocoePn4ACSJkCBGWRYzIRHAESRIlS5g0cfLkIpQo\
		UqaspFLFyhUsWbRsWRixAZeVXbx8uQImjJgxCMg0LmOG5oEzaNKoWcOmjZs3\
		jeHEkTOHTh07d/Dk0bOnAZ/GDfr4gfIHUCBBgwgVMtTgEKJEuJM3UJRmEaND\
		h5Qrb+ToziPcAQEAOw==
	}]
	set bluebrainicon [image create photo ibrainblue -data {
	    
	    R0lGODlhEgASAOcAAP3+/f79//z//fz89/z7+/Ly8rWtu/97AAAq//T59/z5\
		+v77/vv+/v7+/vz+/P3+/vbz+LKawvf/9v77/f3+9/r88sK6yvX69Pr+/P39\
		/vf597qxwvz9+9PB2Id9dkBEQScrJVtfWYOEhv789mRXcTo4OykmJY+NiI2K\
		ioOBimdnYOfd5mtsdDQwNCIiKmpna5WTlYKChmRoZVRIYsOu0G5te5WPkW9x\
		cWVlZVRUVHp2fXxgktXO1oV1hXR5d3N0cHZ2dnx8fMrLyrvAvbatwPz8+dfJ\
		0ZOFmrCytNfT1szMzL6+vqGfoaOeosrQyIKAhf78/vr+/fv++eLc37apuMHD\
		wuLi4s/Pz76/vq6vsL61voB9hPj7+p6Ho7CxsdnZ2aysrL+/v6urq2lnaubZ\
		6vj8/Ozn8qusr8vLy83NzZqampKSkn9/f8PDwvz59/77+f/8+f38//j7+fj9\
		+Pz7+fj6+dHNz7y8vMnJyaOjo5iYmPb29v3/+/v////9+v36///7/Pr+/vz8\
		+rCwsM7OzqampvHx8f/////+/f/+/MTExK6uruTk5Onp6cLCwt7e3gf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0Iwf0\
		Iwf0Iwf0Iwf0Iwf0Iwf0IyH5BAEKAP8ALAAAAAASABIAAAj1AAEEEDCAQAED\
		BxAcWJhAwQIGDSI6eAAhAoKLGDFKmBCRQoWEGUMisHAhIoaFCUGCvJgyQwMN\
		GFOiXBhzA4cOMQ94+AAihAiVF0ewVEiihIkTKFKoQHlxBcuFLFq4eAEjhowZ\
		K2kMRVnDxg0cOXTsWMlDocoePn4ACSJkCBGWRYzIRHAESRIlS5g0cfLkIpQo\
		UqaspFLFyhUsWbRsWRixAZeVXbx8uQImjJgxCMg0LmOG5oEzaNKoWcOmjZs3\
		jeHEkTOHTh07d/Dk0bOnAZ/GDfr4gfIHUCBBgwgVMtTgEKJEuJM3UJRmEaND\
		h5Qrb+ToziPcAQEAOw==
	}]
	set lightbluebrainicon [image create photo ibrainlightblue -data {
	    R0lGODlhEgASAOcAAP3+/f79//z//fz89/z7+/Ly8rWtuxj06QAq//T59/z5\
		+v77/vv+/v7+/vz+/P3+/vbz+LKawvf/9v77/f3+9/r88sK6yvX69Pr+/P39\
		/vf597qxwvz9+9PB2Id9dkBEQScrJVtfWYOEhv789mRXcTo4OykmJY+NiI2K\
		ioOBimdnYOfd5mtsdDQwNCIiKmpna5WTlYKChmRoZVRIYsOu0G5te5WPkW9x\
		cWVlZVRUVHp2fXxgktXO1oV1hXR5d3N0cHZ2dnx8fMrLyrvAvbatwPz8+dfJ\
		0ZOFmrCytNfT1szMzL6+vqGfoaOeosrQyIKAhf78/vr+/fv++eLc37apuMHD\
		wuLi4s/Pz76/vq6vsL61voB9hPj7+p6Ho7CxsdnZ2aysrL+/v6urq2lnaubZ\
		6vj8/Ozn8qusr8vLy83NzZqampKSkn9/f8PDwvz59/77+f/8+f38//j7+fj9\
		+Pz7+fj6+dHNz7y8vMnJyaOjo5iYmPb29v3/+/v////9+v36///7/Pr+/vz8\
		+rCwsM7OzqampvHx8f/////+/f/+/MTExK6uruTk5Onp6cLCwt7e3v/yAP/y\
		AP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/y\
		AP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/y\
		AP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/y\
		AP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/y\
		AP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/y\
		AP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/y\
		AP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/yAP/y\
		AP/yAP/yAP/yAP/yAP/yACH5BAEKAP8ALAAAAAASABIAAAj2AAEEEDCAQAED\
		BxAcWJhAwQIGDSI6eAAhAoKLGDFKmBCRQoWEGTGCtHAhIoaFCUGmvJgyQwMN\
		IhWiXChyA4cOIg94+AAihAiVF0ewVEiihIkTKFKoQHlxBcuFLFq4eAEjhowZ\
		IBHQGIqyho0bOHLo2JGVh0yWPXz8ABJEyBAiLIsYSZnwCJIkSpYwaeLkyUUo\
		UaRMyUqlipUrWLJo2bIwYgMuWbt4+XIFTBgxYxCQcVzGDM0DZ9CkUbOGTRs3\
		bxzDiSNnDp06du7gyaNnTwM+jhv08QPlD6BAggYRKmSowSFEiXIrb6AozSJG\
		hw4tX97I0Z1HuQMCADs=
	    
	}]
	set rainbowbrainicon [image create photo ibrainrainbow -data {
	    R0lGODlhEgASAOcAAP3+/f79//z//fz89/z7+/Ly8rWtu4wA//8IAPT59/z5\
		+v77/vv+/v7+/vz+/P3+/vbz+LKawgB3//f/9v77/f3+9/r88sK6yvX69Pr+\
		/AD/CP9lAP39/vf597qxwvz9+9PB2EBEQScrJVtfWYOEhv789jo4OykmJY+N\
		iI2KioOBimdnYP/2AOfd5v/uADQwNCIiKmpna5WTlYKChmRoZVRIYsOu0P+M\
		AG5te5WPkW9xcWVlZVRUVHp2fXxgktXO1oV1hXR5d3N0cHZ2dnx8fMrLyrvA\
		vbatwBH/APz8+dfJ0ZOFmrCytNfT1szMzL6+vqGfoaOeosrQyIKAhf78/vr+\
		/fv++eLc3/QfGLapuMHDwuLi4s/Pz76/vq6vsL61voB9hAAM//j7+p6Ho7Cx\
		sdnZ2aysrL+/v6urq2lnagAq/+bZ6vj8/Ozn8qusr8vLy83NzZqampKSkn9/\
		f8PDwvz59/77+f/8+f38//j7+fj9+Pz7+fj6+dHNz7y8vMnJyaOjo5iYmPb2\
		9v3/+/v////9+v36///7/Pr+/vz8+rCwsM7OzqampvHx8f/////+/f/+/MTE\
		xK6uruTk5Onp6cLCwt7e3hH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/\
		ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/\
		ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/\
		ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/\
		ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/\
		ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/\
		ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/ABH/\
		ABH/ABH/ABH/ABH/ABH/ACH5BAEKAP8ALAAAAAASABIAAAj+AAEEEDCAQAED\
		BxIeQJBAwQIGDSI6eAAhggSFCRFonEAhYgULEkKGVKhR4wUMETNo0CByZEaN\
		GzZwaNBhJUuRJBHE3ODhAwibN0OIGEEC5s4SQFeaOIEihYoVOmOyaOGiqtUX\
		MGLImEGjhlQWNqxWvXEDRw4dO3j08MGiLYsfVsneABJEyBAiRYwcQcI3iRIX\
		cm8sYdLEyRMoUaRM4UulipUrZLFgyaJlC5cuXr6ACRMmYgMxNyRjGUOmDBcz\
		Z9CkUbPGM5s2bUS7eQMnjpw5dOrY8XwHTx49e/j08fMHUCBBDQZ5bkCoEBVD\
		hxAlUrSIUaMGjh5BWs69QSQ4kiYMOXLUvTulSn4sLQ8IADs=
	    
	}]
	
	#A person icon for "Subject" nodes
	set personicon [image create photo ipersonicon -data {
	    R0lGODlhEgASAKEAAAAAAP8AAP///wAAACH+FUNyZWF0ZWQgd2l0aCBUaGUg\
		R0lNUAAsAAAAABIAEgAAAi6UL6CAjZqgeyzKmc6qmG9sSB8YWaS2nNS5AUHQ\
		NpcLo+SljmyFd0/+YwVBuF4BADs=
	}]


	#Here are a couple arrows
	#This one has a bend in it
	set arrowicon2 [image create bitmap iarrow2 -data {          
	    
	    #define arrow2_width 16
	    #define arrow2_height 16
	    static unsigned char arrow2_bits[] = {
		0x10, 0x00, 0x18, 0x00, 0xfc, 0x1f, 0xfe, 0x3f, 0xff, 0x3f, 0xfe, 0x3f,
		0xfc, 0x3f, 0x18, 0x3e, 0x10, 0x3e, 0x00, 0x3e, 0x00, 0x3e, 0x80, 0xff,
		0x00, 0x7f, 0x00, 0x3e, 0x00, 0x1c, 0x00, 0x08};
	    
	    
    	}]
	
	#This one is diagonal
	set arrowicon [image create bitmap iarrow -data { 

	    #define arrow_width 17
	    #define arrow_height 17
	    static char arrow_bits[] = {
		0x1f,0x00,0x00,0x0f,0x00,0x00,0xcf,0x07,0x00,0x3f,0x08,0x00,0x99,0x13,0x00,
		0x68,0x24,0x00,0xe4,0x4b,0x00,0xd4,0x57,0x00,0xd4,0x57,0x00,0xd4,0x57,0x00,
		0xa4,0x4f,0x00,0x48,0x2c,0x00,0x90,0x33,0x01,0x20,0xf8,0x01,0xc0,0xe7,0x01,
		0x00,0xe0,0x01,0x00,0xf0,0x01,0x00,0x90,0x00,0x00,0x00,0x11,0x00,0x00,0x00,
		0x48,0x79,0x15,0x08,0x98,0xd8,0x24,0x08 };
	}]

	#This one is in color and over a green brain
	set arrowbrain [image create photo iarrowbrain -data {
	    
	    R0lGODlhEgASAMYAAAcP8v7+/huZFgf0I/T59/z5+v77/vv+/vf/9v77/cK6\
		yvX69P39/rqxwvz9+0BEQScrJVtfWYOEhv789o+NiI2KioOBimdnYOfd5mts\
		dJWTlYKChmRoZVRIYsOu0GVlZVRUVHp2fXxgktXO1oV1hXx8fMrLyrvAvbat\
		wPz8+dfJ0ZOFmrCytKGfoaOeosrQyIKAhf78/vr+/fv++eLc37apuMHDwq6v\
		sL61voB9hPj7+p6Ho7CxsdnZ2aurq2lnavj8/Ozn8qusr8vLy83NzcPDwv/8\
		+f38//j7+fj9+Pz7+fj6+dHNz7y8vMnJyaOjo/v////9+v36///7/Pr+/vz8\
		+rCwsM7OzqampvHx8cTExK6urunp6cLCwv//////////////////////////\
		////////////////////////////////////////////////////////////\
		/////////////////////////////////////////////////ywAAAAAEgAS\
		AAAHvoAAgoMBAgMCiAQFBgcBAYOCA5KTkwgJjpCUmgMKC5iQhoeUhgIMjwAD\
		g4iroYcNDqiSgw8QERKhoROSpIMUFRYXq5IYu4gZgxobHB2tHruHiIMfICEi\
		rSPQuySDJSYnKLspKqSGKyyDLS4vMJIxMjM0rTU2gzc4OQKOjjqtOzw9g3z8\
		SKUPSBBEh4QMITKoiCB9Ro4gSaJkCZMmTp5AAqAPSpQYUqZQqWLlCpYskPSp\
		1KeFyJaNK1dy6bIRQCAAOw==
	} ]
	
	set cactusicon [image create photo icactus -data { 

	    R0lGODlhEQARAPcAMf///wR8HAR8JASELASENAyEPASERCSMJCSMLCyUHCSM
	    NCyUNByMPBSMTByMTFykFFykHEScLFykJEScRDycXEScXDScZESkdFykPFys
	    VEykbGysJHSsHIy0FHS0NIS0HHy0THy8hJS8FKTEDJTETJzETKTETKzEDKTM
	    TLTMTJzEVKTMbKTMhKzMVLzMBLzMLMTUJPz89P9oLAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	    AAAAAAAAAAAAAAAAAAAAACH5BAEAADIALAAAAAARABEAAAiWAGUIHEiwoEGB
	    HhJiMHFw4AsKEgwYEKHgRUMZGBhENMBgQwSLDAm+iHAggkQDGwSYMCAgg0MZ
	    BxSYlJhyJUqBKRpsSLBgpoEIAjZIBCFQhIEJPH2mbCBxoFGkPU8ubTrwaFKp
	    Jy0iZLogKk0BHgy+YGDAK0oDDV8IMItBgFaDA2Se5CDg4lqlBt6KjPBgg4K/
	    Hi8KHhgQADs=
	    
	}]





	#------------------------------------------------------------------------------------------
	# End of icon image definitions
	#------------------------------------------------------------------------------------------
		
    };#End of the "create" procedure
    
    
    # Initialize an element of the tree.
    # Internal use only
    #
    proc dfltconfig {w v} {
	variable Tree
	set Tree($w:$v:children) {}
	set Tree($w:$v:open) 0
	set Tree($w:$v:icon) {}
	set Tree($w:$v:tags) {}
	set Tree($w:$v:linecolor) gray50
    }
    
    #
    # Pass configuration options to the tree widget
    #
    proc config {w args} {
	eval $w config $args

    }

    #Configure a single node of the tree
    proc nodeconfig {w v args} {
	foreach {op arg} $args {
	    switch -exact -- $op {
		-linecolor {set Tree($w:$v:linecolor) $arg}
		-image {set Tree($w:$v:icon) $arg}
		-tags {set Tree($w:$v:tags) $arg}
	    }
	}
    }
    
    proc itemexists {w v} {
	
	variable Tree
	
	if {[info exists Tree($w:$v:open)]} {
	    return 1
	} else {return 0}

    }


    proc gettreeobjects {w} {
    	variable Tree
    	foreach t [array names Tree $w:*] {
    		lappend n $t
    	}
	return $n
    }

    #
    # Insert a new element $v into the tree $w.
    #
    proc newitem {w v args} {
	variable Tree
	set dir [file dirname $v]
	set n [file tail $v]
	if {![info exists Tree($w:$dir:open)]} {
	    error "parent item \"$dir\" is missing"
	}
	set i [lsearch -exact $Tree($w:$dir:children) $n]
	if {$i>=0} {
	    error "item \"$v\" already exists"
	}
	lappend Tree($w:$dir:children) $n
	set Tree($w:$dir:children) [lsort $Tree($w:$dir:children)]
	Tree::dfltconfig $w $v
	foreach {op arg} $args {
	    switch -exact -- $op {
		-linecolor {set Tree($w:$v:linecolor) $arg}
		-image {set Tree($w:$v:icon) $arg}
		-tags {set Tree($w:$v:tags) $arg}
	    }
	}
	Tree::buildwhenidle $w
}

#
# Delete element $v from the tree $w.  If $v is /, then the widget is
# deleted.
#
proc delitem {w v} {
    variable Tree
    if {![info exists Tree($w:$v:open)]} return
    if {[string compare $v /]==0} {
	# delete the whole widget
	catch {destroy $w}
	foreach t [array names Tree $w:*] {
	    unset Tree($t)
    }
}
foreach c $Tree($w:$v:children) {
    catch {Tree::delitem $w $v/$c}
}
unset Tree($w:$v:open)
unset Tree($w:$v:children)
unset Tree($w:$v:icon)
set dir [file dirname $v]
set n [file tail $v]
set i [lsearch -exact $Tree($w:$dir:children) $n]
if {$i>=0} {
    set Tree($w:$dir:children) [lreplace $Tree($w:$dir:children) $i $i]
  }
  Tree::buildwhenidle $w
}

#
# Change the selection to the indicated item
#
proc setselection {w v} {
    variable Tree
    set Tree($w:selection) [list $v]
    Tree::drawselection $w
}

proc setCurrent {w v} {
    
    variable Tree
    set Tree($w:current) [ list $v ] 
    Tree::drawCurrent $w 
}

proc addselection {w v} {
    variable Tree
    lappend Tree($w:selection) $v
    set Tree($w:selection) [ linsert $Tree($w:selection) 0 $v ]
    Tree::drawselection $w
}


#Accessor method for the name of the element currently selected
proc getselection {w {option_list 0}} {
    variable Tree
    if {[llength $Tree($w:selection)]} {
	foreach p $Tree($w:selection) {
	    set q [string last / $p]
	    if {$q == -1} {lappend result $p} else {
		lappend result [string range $p [expr $q + 1] end]
	    }	
	}
	if {$option_list == 0} {
	    return [lindex $result 0]
	}
	return $result
    }
}


#
# Retrieve the current selection (with fully qualified path name)
#
proc getCurrentPath w {
    variable Tree
    if {[llength $Tree($w:current)]} {
	return $Tree($w:current)
    }
}

proc getselectionpath w {
    variable Tree
    if {[llength $Tree($w:selection)]} {
	return $Tree($w:selection)
    }
}

#
# Bitmaps used to show which parts of the tree can be opened.
#
set maskdata "#define solid_width 9\n#define solid_height 9"
append maskdata {
    static unsigned char solid_bits[] = { 
	0xff, 0x01, 0xff, 0x01, 0xff, 0x01, 0xff, 0x01, 0xff, 0x01, 0xff, 0x01,
	0xff, 0x01, 0xff, 0x01, 0xff, 0x01
    };
}
set data "#define open_width 9\n#define open_height 9"
append data {
    static unsigned char open_bits[] = {
	0xff, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x7d, 0x01, 0x01, 0x01,
	0x01, 0x01, 0x01, 0x01, 0xff, 0x01
    };
}
image create bitmap Tree::openbm -data $data -maskdata $maskdata \
    -foreground black -background white
set data "#define closed_width 9\n#define closed_height 9"
append data {
    static unsigned char closed_bits[] = {
	0xff, 0x01, 0x01, 0x01, 0x11, 0x01, 0x11, 0x01, 0x7d, 0x01, 0x11, 0x01,
	0x11, 0x01, 0x01, 0x01, 0xff, 0x01
    };
}
image create bitmap Tree::closedbm -data $data -maskdata $maskdata \
    -foreground black -background white

# Internal use only.
# Draw the tree on the canvas
proc build w {
    variable Tree
    $w delete all
    catch {unset Tree($w:buildpending)}
    set Tree($w:y) 30
    Tree::buildlayer $w / 20
    $w config -scrollregion [$w bbox all]
    Tree::drawselection $w
}

# Internal use only.
# Build a single layer of the tree on the canvas.  Indent by $in pixels
proc buildlayer {w v in} {
    variable Tree
    
    incr in 5  
    if {$v=="/"} {
	set vx {}
    } else {
	set vx $v
    }

    set start [expr $Tree($w:y)-10]
    foreach c $Tree($w:$v:children) {
	set y $Tree($w:y)
	incr Tree($w:y) 19
	set li($y) [$w create line $in $y [expr $in+15] $y -fill $Tree($w:$vx/$c:linecolor) -width 3]
	set icon $Tree($w:$vx/$c:icon)
	set taglist x
	foreach tag $Tree($w:$vx/$c:tags) {
	    lappend taglist $tag
	}
	set x [expr $in+16]
	if {[string length $icon]>0} {
	    set k [$w create image $x $y -image $icon -anchor w -tags $taglist]
	    incr x 20
	    set Tree($w:tag:$k) $vx/$c
	}
	set j [$w create text $x $y -text $c -font $Tree(font) \
		   -anchor w -tags $taglist]
	set Tree($w:tag:$j) $vx/$c
	set Tree($w:$vx/$c:tag) $j
	if {[string length $Tree($w:$vx/$c:children)]} {
	    if {$Tree($w:$vx/$c:open)} {
		set j [$w create image $in $y -image Tree::openbm]
		$w bind $j <1> "set {::Tree::Tree($w:$vx/$c:open)} 0; ::Tree::build $w"
		Tree::buildlayer $w $vx/$c [expr $in+18]
	    } else {
		set j [$w create image $in $y -image Tree::closedbm]
		$w bind $j <1> "set {::Tree::Tree($w:$vx/$c:open)} 1; ::Tree::build $w"
	    }
	}
    }

    set j [$w create line $in $start $in [expr $y+2] -fill gray50 -width 3]
    $w lower $j
    foreach index [array names li] {
	$w lower $li($index) $j
    }
}

# Open a branch of a tree
#
proc open {w v} {
  variable Tree
  if {[info exists Tree($w:$v:open)] && $Tree($w:$v:open)==0
      && [info exists Tree($w:$v:children)]
      && [string length $Tree($w:$v:children)]>0} {
    set Tree($w:$v:open) 1
    Tree::build $w
  }
}

proc close {w v} {
  variable Tree
  if {[info exists Tree($w:$v:open)] && $Tree($w:$v:open)==1} {
    set Tree($w:$v:open) 0
    Tree::build $w
  }
}

proc eraseCurrentBox w {
    
    variable Tree
    
    if {[llength $Tree($w:selidcurrent)] > 0} {
	foreach x $Tree($w:selidcurrent) {
	    $w delete $x
	}
    }
    
    #unset $Tree($w:selidcurrent)
    #unset $Tree($w:current)
}

proc drawCurrent w {
    
    variable Tree
    
    if {[llength $Tree($w:selidcurrent)] > 0} {
	foreach x $Tree($w:selidcurrent) {
	   $w delete $x
	}
    }

    foreach v $Tree($w:current) {
	if {[string length $v]==0} return
	if {![info exists Tree($w:$v:tag)]} return
	set bbox [$w bbox $Tree($w:$v:tag)]
	if {[llength $bbox]==4} {
	    set i [eval $w create rectangle $bbox -outline black]
	lappend Tree($w:selidcurrent) $i
	    $w lower $i
	} else {
	    set Tree($w:selidcurrent) {}
	}
    }
 }


# Internal use only.
# Draw the selection highlight
proc drawselection w {
    variable Tree

    if {[llength $Tree($w:selidx)] > 0} {
	foreach x $Tree($w:selidx) {
	$w delete $x
	}
	
    }
    
    foreach v $Tree($w:selection) {
	if {[string length $v]==0} return
	if {![info exists Tree($w:$v:tag)]} return
	set bbox [$w bbox $Tree($w:$v:tag)]
	if {[llength $bbox]==4} {
	    set i [eval $w create rectangle $bbox -fill skyblue -outline {{}} ] 
	    lappend Tree($w:selidx) $i
	    $w lower $i
	} else {
	    set Tree($w:selidx) {}
	}
    }
}




# Internal use only
# Call Tree::build then next time we're idle
proc buildwhenidle w {
  variable Tree
  if {![info exists Tree($w:buildpending)]} {
    set Tree($w:buildpending) 1
    after idle "Tree::build $w"
  }
}

#
# Return the full pathname of the label for widget $w that is located
# at real coordinates $x, $y
#
proc labelat {w x y} {
  set x [$w canvasx $x]
  set y [$w canvasy $y]
  variable Tree
  foreach m [$w find overlapping $x $y $x $y] {
    if {[info exists Tree($w:tag:$m)]} {
      return $Tree($w:tag:$m)
    }
  }
  return ""
}

}
########################################################################################
#				End of Tree Widget Definition			       #
########################################################################################
########################################################################################
########################################################################################




