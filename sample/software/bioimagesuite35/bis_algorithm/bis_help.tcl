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

#
# AUTHOR Hirohito Okuda, hirohito.okuda@yale.edu
# 

lappend auto_path [ file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] main ]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] bis_algorithm]

#if { $env(TESTING) != "" } { 
#    lappend auto_path [file join  $env(TESTING)  bis_algorithm]
#    puts stdout "auto_path = $auto_path"
#}

package require bis_algorithm 1.0
package require vtkpxcontrib  1.0
package require bis_common 1.0
#
# 
#

itcl::class bis_help {

    public variable tools1
    public variable categories ""

#bis_computeaveragebrain missed
# bis_fastpostprocess missed

    constructor { fname } {  
	set fin [ open $fname r ]
	set tools1 ""
	while { [ gets $fin line ] >=0 } {
	    if { [ string first "\#" $line ]  == -1 } {
		lappend tools1 "[ file rootname [ string trim $line ]]"
	    }
	}
	close $fin

	set categories [ ::bis_common::GetCategories ]
    }

    # Print short description of all the command line tools
    public method Summarize { } 
    public method GenerateHTML { use_stylesheet  }
    public method GenerateLatex {   }
    public method InsertFile { chan file } 

    private variable outputdirectory   ""
    private variable pathdirectory     ""
    private variable headpart html/headpart.html
    private variable tailpart html/tailpart.html
    private variable headpart2  html/headpart.html
    private variable tailpart2 html/tailpart.html


    private variable headlatex  html/head.tex
    private variable introlatex html/intro.tex
    private variable taillatex  html/tail.tex

    public method SetHTMLDirectories { outdir pathdir }

    public method ToLatexString { line { mode 0 } }
    public method SetLatexDirectories { outdir pathdir }
}


#
# Print short description of all the command line tools
#

itcl::body bis_help::SetHTMLDirectories { outdir pathdir } {

    set outputdirectory [ file normalize $outdir ]
    set pathdirectory   [ file normalize $pathdir ]
    file delete -force  $outputdirectory 
    file mkdir $outputdirectory
}

itcl::body bis_help::SetLatexDirectories { outdir pathdir } {

    set outputdirectory [ file normalize $outdir ]
    set pathdirectory   [ file normalize $pathdir ]
    if { [ file exists  $outputdirectory  ] == 0 } {
	file mkdir $outputdirectory
    }
}



itcl::body bis_help::Summarize { } {
    foreach tool $tools {
#	puts stderr "Reading $tool\n"
	package require $tool 
	set alg [$tool [pxvtable::vnewobj]]
	#    $alg PrintUsage
	set d [ $alg GetDescription ]
#	puts stderr "${tool}.tcl : $d"
    }
}

#
# 
#

itcl::body bis_help::InsertFile { chan filename  } {

    set fs [open  $filename r ]
    while { [gets $fs line ]>=0 } {
	puts $chan "$line"
    }
    close $fs
}

#
# 
#
# ---------------------------------------------------------------------------------------------------------------
itcl::body bis_help::GenerateHTML { use_stylesheet  } {

    puts stderr "+++ bis_help::GenerateHTML"


    set qlist [lsort -ascii  $tools1 ]
    set slist ""
    foreach tool $qlist {
	set ok 0 
	catch { package require $tool ; set ok 1  }
	if { $ok == 1 } {
	    lappend slist $tool
	}  else {
	    puts stderr "--------- Ignoring $tool "
	}
    }

    


    #index.html
    set filename index.html
    set chan [open $outputdirectory/$filename w ]

    if { $use_stylesheet  } {
	InsertFile $chan [ file join $pathdirectory $headpart ]
	puts $chan "<div id=\"pagetitle\">"
	puts $chan "<center>BIS Command Line Tools Index </center>"
	puts $chan "</div>"
    } else {
	puts $chan "<HTML><HEAD background=\"white\"><TITLE>BIS - index </TITLE></HEAD><BODY>"
	puts $chan "<font size=\"2\" >"
	puts $chan "<H2><CENTER>BioImage Suite Command Line Tools Index </CENTER></H2>"
    }

    puts $chan "<HR><P><B>Note:</B> Any tool can be executed also as an applet with a graphical user interface using the --dogui 1 flag.</P>"
    puts $chan "<P>For example in the case of bis_smoothimage, you can invoke this as an applet using:</P>"
    puts $chan "<PRE>bis_smoothimage.tcl --dogui 1</PRE><HR>"


    foreach c $categories { 
	set tools($c) ""
    }


    set alltools ""
    foreach tool $slist {
	set algorithm($tool) [$tool [pxvtable::vnewobj]]
	set alg $algorithm($tool)
	set categ  [$alg GetCategory]
	if { $categ == "" } {
	    set categ "other"
	}
	#	puts stderr "tool categ = $tool $categ"
	lappend tools(${categ}) $tool
	if { [ lsearch -exact $categories $categ ] == -1 } {
	    lappend categories $categ
	}
    }
    
    #set clist [ lsort -ascii $categories]
    #puts stderr "categories=$categories"

    for { set i 0 } { $i < [ llength $categories ] } { incr i } {
	set categ  [ lindex $categories $i ]
	#puts stderr "category =$categ, $tools($categ)"
	puts $chan "<H2>$categ</H2>"
	#	puts stderr "\n ++++++++++++++++++++++ $categ"
	foreach tool $tools($categ) {
	    set alg $algorithm($tool)
	    puts $chan "<A HREF=\"man_$tool.html\" NAME=\"$tool\">${tool}</A> </span>, [$alg GetDescription] <br>"
	}
    }

    if { $use_stylesheet  } {
	InsertFile $chan [ file join $pathdirectory $tailpart ]
    } else {
	puts $chan "<hr>"
	#	puts $chan "This is the man pages for the command line tools of the upcoming 3.0 release of <a href=\"http://www.bioimagesuite.org\">BioImage Suite.</a>"
	puts $chan "</font>"
	puts $chan "</BODY></HTML>"
    }

    close $chan
    #    exit
    #
    # generate description page for each command line tool
    #

    foreach tool $slist {
	set alg $algorithm($tool)
	set ok [$alg GetCmdLineOptionsList]	

	set filename ${outputdirectory}/man_${tool}.html
	puts stderr "++++++ generating $filename ..."
	set chan [open $filename w ]

	if { $use_stylesheet  } {
	    InsertFile $chan [ file join $pathdirectory $headpart2 ]
	    puts $chan "<H2><CENTER>${tool}</CENTER></H2>"
	    puts $chan "<br> <font size=\"2\" > <i>This part is under construction</i> </font>"
	} else {
	    puts $chan "<HTML><HEAD><TITLE>BioImage Suite - ${tool} </TITLE></HEAD><BODY>"
	    puts $chan "<H2><CENTER><a href=\"index.html\">BioImage Suite Command Line Tools</a></CENTER></H2>"
	}

	puts $chan "<font size=\"2\" >"
	puts $chan "<br> <br><H3>NAME</H3>"
	puts $chan "${tool}.tcl --[$alg GetDescription]"

	    puts $chan "<br> <br><H3>SYNOPSIS</H3>"
	    puts $chan "</font>"
	    
#	    puts stderr "category = [$alg GetCategory ] "

	    puts $chan "<font size=\"3\" >"

	    puts $chan "[$alg GetSynopsis html]"
	    puts $chan "</font>"



	    puts $chan "<font size=\"2\" >"
	    puts $chan "<br> <br><H3>DESCRIPTION</H3>"
	    puts $chan "${tool}.tcl [$alg GetDetailDescription html] "

	    
	    puts $chan "<br> <br><H3>BACKWARD COMPATIBILITY ISSUES</H3>"
	    puts $chan "[$alg GetBackwardCompatibility]"



	    puts $chan "<br> <br><H3>Authors</H3>"
	    puts $chan "[$alg GetAuthors]"
	    puts $chan "<br>"

#	    puts $chan "<H3>Status</H3>"
#	    puts $chan "([ $alg GetCompletionStatus ])"
	    itcl::delete object $alg


	if { $use_stylesheet  } {
	    InsertFile $chan [ file join $pathdirectory $tailpart2 ]
	} else {
	    puts $chan ""
	    puts $chan "<HR><CENTER><A HREF=\"index.html\" NAME=\"Back to index\">\[Return to Command Line Tools Index\]</A></CENTER>"
	    puts $chan "</font>"
	    puts $chan "</BODY></HTML>"
	}
	close $chan
    }

    #
    # generate description page for test script
    #

}
# ---------------------------------------------------------------------------------
itcl::body bis_help::ToLatexString { line { mode 0 } } {

    if { $mode == 0 } {
	regsub -all "_" $line "\\_" out
    } else {
	regsub -all "_" $line "" out
    }
    regsub -all "%" $out "\\%" out

#    puts stderr "$line -> $out"
    return $out

    puts stdout "Output saved in $outputdirectory"
}
# ---------------------------------------------------------------------------------
itcl::body bis_help::GenerateLatex { } {

    puts stderr "bis_help::GenerateLatex"


    set qlist [lsort -ascii  $tools1 ]
    set slist ""
    foreach tool $qlist {
	set ok 0 
	catch { package require $tool ; set ok 1  }
	if { $ok == 1 } {
	    lappend slist $tool
	}  else {
	    puts stderr "--------- Ignoring $tool "
	}
    }

    #index.html
    set filename biotools.tex
    set chan [open $outputdirectory/$filename w ]

    InsertFile $chan [ file join $pathdirectory $headlatex ]


    foreach c $categories { 
	set tools($c) ""
    }
    

    set alltools ""
    foreach tool $slist {
	set algorithm($tool) [$tool [pxvtable::vnewobj]]
	set alg $algorithm($tool)
	set categ  [$alg GetCategory]
	if { $categ == "" } {
	    set categ "other"
	}
	puts stdout "tool categ = $tool $categ"
	lappend tools(${categ}) $tool
	if { [ lsearch -exact $categories $categ ] == -1 } {
	    lappend categories $categ
	}
    }
    
    InsertFile $chan [ file join $pathdirectory $introlatex ]

    puts $chan "\\chapter{Catalog}"

    puts $chan "\\textbf{Note:} The manual pages for each module are automatically generated from the BioImage Suite source code."

    for { set i 0 } { $i < [ llength $categories ] } { incr i } {
	set categ  [ lindex $categories $i ]
	puts $chan "\\paragraph*{$categ}"
	puts $chan "\\begin{compactenum}"
	puts stderr "\n ++++++++++++++++++++++ $categ"
	foreach tool $tools($categ) {
	    set alg $algorithm($tool)
	    set toolname [ $this ToLatexString $tool ]
	    set guiname [ $this ToLatexString [ $alg GetGUIName ] ]
	    set refname [ $this ToLatexString $tool 1 ]
	    puts $chan "\\item ${guiname} ($toolname)  [ $this ToLatexString [$alg GetDescription]] -- See Section \\ref{$refname} (on page \\pageref{$refname})"
	}
	puts $chan "\\end{compactenum}"
    }

    puts $chan "\n\\clearpage"

    


    for { set i 0 } { $i < [ llength $categories ] } { incr i } {
	
	set categ [ lindex $categories $i ]
	puts $chan "\\clearpage\\chapter{$categ}"
	foreach tool $tools($categ) {

	    set alg $algorithm($tool)
	    set ok [$alg GetCmdLineOptionsList]	
	    #	    set filename ${outputdirectory}/${tool}.html
	    #    puts stderr "generating $filename ..."
	    #set chan [open $filename w ]
	    set toolname [ $this ToLatexString $tool ]
	    set refname [ $this ToLatexString $tool 1 ]
	    set guiname [ $this ToLatexString [ $alg GetGUIName ] ]

	    puts $chan  "\\section{$guiname ($toolname)}"
	    puts $chan  "\\label{$refname}"

	    puts $chan "\\paragraph{Description:}"

	    set d [ $alg GetDescription ] 
	    set desc  [ $this ToLatexString $d ]
	    set ldesc [ $this ToLatexString  [ $alg GetDetailDescription tex ] ]


	    puts $chan "${toolname}.tcl -- $desc"

	    puts $chan "\\paragraph{Synopsis:}"
	    puts $chan "[ $alg GetSynopsis tex ]"

	    puts $chan "\\paragraph{Detailed Description:}"
	    puts $chan "\\textbf{${toolname}.tcl} $ldesc"

	    
	    puts $chan "\\paragraph{Backward Compatibility Issues:}"
	    puts $chan "[ $this ToLatexString [$alg GetBackwardCompatibility]]"

	    puts $chan "\\paragraph{Authors:}"
	    puts $chan "[ $this ToLatexString [$alg GetAuthors]]"


	    #	    puts $chan "\\paragraph{Status:}"
	    #	    puts $chan "[ $this ToLatexString [ $alg GetCompletionStatus ] ]"
	    #	    puts $chan "\\clearpage"
	    puts $chan "\\vspace{0.5\\baselineskip}\\hrule"
	    puts $chan "\\vspace{0.5\\baselineskip}"
	}
    }

    puts $chan "\\appendix"
    puts $chan "\\chapter{Alphabetical Algorithm List}"
    puts $chan "\\begin{compactenum}"

    set sslist [ lsort -ascii $slist ]

    foreach tool $sslist {
	set alg $algorithm($tool)
	set toolname [ $this ToLatexString $tool ]
	set refname [ $this ToLatexString $tool 1 ]
	set guiname [ $this ToLatexString [ $alg GetGUIName ] ]
	puts $chan  "\\item $toolname ($guiname) -- see page \\pageref{$refname}"
	itcl::delete object $alg
    }
    puts $chan "\\end{compactenum}"


    InsertFile $chan [ file join $pathdirectory $taillatex ]
    puts $chan "\\end{document}"
    close $chan
    #
    # generate description page for test script
    #
    puts stdout "Output saved in $outputdirectory/$filename"
}


# ---------------------------------------------------------------------------------------------------------------------------------------------

if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {

    if { [ llength $argv ] < 2  } {
	puts stdout "Usage $argv0  listofscripts directory \[ latex \] "
	exit
    }

    set help [bis_help [pxvtable::vnewobj]  [ lindex $argv 0 ] ]
    set use_stylesheet 0
    
    if { [ llength $argv ] == 2 || [ lindex $argv 2 ] == "html" } {
	$help SetHTMLDirectories [ lindex $argv 1 ] [ file dirname [  info script ] ]
	$help GenerateHTML $use_stylesheet
    } else {
	$help SetLatexDirectories [ lindex $argv 1 ] [ file dirname [  info script ] ]
	$help GenerateLatex 
    }

    exit
}




