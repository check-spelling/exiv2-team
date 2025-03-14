#!/usr/bin/perl
#!/usr/local/bin/perl
##---------------------------------------------------------------------------##
##  File:
##      @(#) man2html 1.2 97/08/12 12:57:30 @(#)
##  Author:
##      Earl Hood, ehood@medusa.acs.uci.edu
##  Description:
##      man2html is a Perl program to convert formatted nroff output
##	to HTML.
##	
##	Recommend command-line options based on platform:
##
##	Platform		Options
##	---------------------------------------------------------------------
##	c2mp			<None, the defaults should be okay>
##	hp9000s700/800		-leftm 1 -topm 8
##	sun4			-sun
##	---------------------------------------------------------------------
##
##---------------------------------------------------------------------------##
##  Copyright (C) 1995-1997	Earl Hood, ehood@medusa.acs.uci.edu
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##  
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##  
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
##  02111-1307, USA
##---------------------------------------------------------------------------##

package Man2Html;

use Getopt::Long;

($PROG = $0) =~ s/.*\///;
$VERSION = "3.0.1";

## Input and outputs filehandles
$InFH	= \*STDIN   unless $InFH;
$OutFH	= \*STDOUT  unless $OutFH;

## Backspace character:  Used in overstriking detection
*bs = \"\b";

##	Hash of section titles and their HTML tag wrapper.
##	This list allows customization of what HTML tag is used for
##	a given section head.
##
##	The section title can be a regular expression.  Therefore, one must
##	be careful about quoting special characters.
##
%SectionHead = (

    '\S.*OPTIONS.*'		=> '<H2>',
    'AUTHORS?'  		=> '<H2>',
    'BUGS'      		=> '<H2>',
    'COMPATIBILITY'		=> '<H2>',
    'DEPENDENCIES'		=> '<H2>',
    'DESCRIPTION'		=> '<H2>',
    'DIAGNOSTICS'		=> '<H2>',
    'ENVIRONMENT'		=> '<H2>',
    'ERRORS'    		=> '<H2>',
    'EXAMPLES'  		=> '<H2>',
    'EXTERNAL INFLUENCES'	=> '<H2>',
    'FILES'      		=> '<H2>',
    'LIMITATIONS'		=> '<H2>',
    'NAME'      		=> '<H2>',
    'NOTES?'    		=> '<H2>',
    'OPTIONS'    		=> '<H2>',
    'REFERENCES'		=> '<H2>',
    'RETURN VALUE'		=> '<H2>',
    'SECTION.*:'		=> '<H2>',
    'SEE ALSO'  		=> '<H2>',
    'STANDARDS CONFORMANCE'	=> '<H2>',
    'STYLE CONVENTION'		=> '<H2>',
    'SYNOPSIS'  		=> '<H2>',
    'SYNTAX'    		=> '<H2>',
    'WARNINGS'  		=> '<H2>',
    '\s+Section.*:'		=> '<H3>',

);

## Fallback tag if above is not found
$HeadFallback = '<H2>';

## Other gobals

$Bare      = 0;		# Skip printing HTML head/foot flag
$BTag	   = 'B';	# Overstrike tag
$CgiUrl    = '';	# CGI URL expression
$Compress  = 0;		# Do blank line compression flag
$K         = 0;		# Do keyword search processing flag
$NoDepage  = 0;		# Do not strip page information
$NoHeads   = 0;		# Do no header detection flag
$SeeAlso   = 0;		# Do only SEE ALSO xrefs flag
$Solaris   = 0;		# Solaris keyword search processing flag
$Sun       = 0;		# Headers not overstriken flag
$Title     = '';	# Title
$UTag	   = 'I';	# Underline tag
$ftsz	   = 7;		# Bottome margin size
$hdsz	   = 7;		# Top margin size
$leftm     = '';	# Left margin pad
$leftmsz   = 0;		# Left margin size
$pgsz	   = 66;	# Size of page size
$txsz      = 52;	# Text body length size

#############################################################################
##	Main Block
#############################################################################
{
    if (get_cli_opts()) {
	if ($K) {
	    man_k();
	} else {
	    do_it();
	}
    } else {
	usage();
    }
}

#############################################################################
##	Subroutines
#############################################################################

sub do_it {

    ##	Define while loop and then eval it when used.  The reason
    ##	is to avoid the regular expression reevaulation in the
    ##	section head detection code.

    $doitcode =<<'EndOfDoItCode';

    my($line, $tmp, $i, $head, $preindent, $see_also, $do);

    $see_also = !$SeeAlso;
    print $OutFH "<!-- Manpage converted by man2html $VERSION -->\n";
    LOOP: while(!eof($InFH)) {
	$blank = 0;
	for ($i=0; $i < $hdsz; $i++) {
	    last LOOP  unless defined($_ = <$InFH>);
	}
	for ($i=0; $i < $txsz; $i++) {
	    last LOOP  unless defined($_ = <$InFH>);

	    ## Check if compress consecutive blank lines
	    if ($Compress and !/\S/) {
		if ($blank) { next; } else { $blank = 1; }
	    } else {
		$blank = 0;
	    }

	    ## Try to check if line space is needed at page boundaries ##
	    if (!$NoDepage && ($i==0 || $i==($txsz-1)) && !/^\s*$/) {
		/^(\s*)/;  $tmp = length($1);
		if ($do) {
		    if ($tmp < $preindent) { print $OutFH "\n"; }
		} else {
		    $do = 1;
		}
		$preindent = $tmp;
	    } else {
		$do = 0;  $preindent = 0;
	    }

	    ## Interpret line
	    $line = $_;
	    entitize(\$_);		# Convert [$<>] to entity references

	    ## Check for 'SEE ALSO' link only
	    if (!$see_also && $CgiUrl && $SeeAlso) {
		($tmp = $line) =~ s/.\010//go;
		if ($tmp =~ /^\s*SEE\s+ALSO\s*$/o) { $see_also = 1; }
		else { $see_also = 0; }
	    }

	    ## Create anchor links for manpage references
	    s/((((.\010)+)?[\+_\.\w-])+\(((.\010)+)?
	      \d((.\010)+)?\w?\))
	     /make_xref($1)
	     /geox  if $see_also;

	    ## Emphasize underlined words
	    # s/((_\010[^_])+[\.\(\)_]?(_\010[^_])+\)?)/emphasize($1)/oge;
	    # s/((_\010[^_])+([\.\(\)_]?(_\010[^_])+)?)/emphasize($1)/oge;
	    #
	    # The previous expressions were trying to be clever about
	    # detecting underlined text which contain non-alphanumeric
	    # characters.  nroff will not underline non-alphanumeric
	    # characters in an underlined phrase, and the above was trying
	    # to detect that.  It does not work all the time, and it
	    # screws up other text, so a simplified expression is used.

	    s/((_\010[^_])+)/emphasize($1)/oge;

	    $secth = 0;
	    ## Check for strong text and headings
	    if ($Sun || /.\010./o) {
		if (!$NoHeads) {
		    $line =~ s/.\010//go;
		    $tmp = $HeadFallback;
EndOfDoItCode

    ##  Create switch statement for detecting a heading
    ##
    $doitcode .= "HEADSW: {\n";
    foreach $head (keys %SectionHead) {
	$doitcode .= join("", "\$tmp = '$SectionHead{$head}', ",
			      "\$secth = 1, last HEADSW  ",
			      "if \$line =~ /^$leftm$head/o;\n");
    }
    $doitcode .= "}\n";

    ##  Rest of routine
    ##
    $doitcode .=<<'EndOfDoItCode';
		    if ($secth || $line =~ /^$leftm\S/o) {
			chop $line;
			$_ = $tmp . $line . $tmp;
			s%<([^>]*)>$%</$1>%;
			$_ = "\n</PRE>\n" . $_ . "<PRE>\n";
		    } else {
			s/(((.\010)+.)+)/strongize($1)/oge;
		    }
		} else {
		    s/(((.\010)+.)+)/strongize($1)/oge;
		}
	    }
	    print $OutFH $_;
	}

	for ($i=0; $i < $ftsz; $i++) {
	    last LOOP  unless defined($_ = <$InFH>);
	}
    }
EndOfDoItCode


    ##	Perform processing.

    printhead()  unless $Bare;
    print $OutFH "<PRE>\n";
    eval $doitcode;			# $doitcode defined above
    print $OutFH "</PRE>\n";
    printtail()  unless $Bare;
}

##---------------------------------------------------------------------------
##
sub get_cli_opts {
    return 0  unless
    GetOptions(
	"bare",		# Leave out HTML, HEAD, BODY tags.
	"belem=s",	# HTML Element for overstriked text (def: "B")
	"botm=i",	# Number of lines for bottom margin (def: 7)
	"cgiurl=s",	# CGI URL for linking to other manpages
	"cgiurlexp=s",	# CGI URL Perl expr for linking to other manpages
	"compress",	# Compress consecutive blank lines
	"headmap=s",	# Filename of user section head map file
	"k",		# Process input from 'man -k' output.
	"leftm=i",	# Character width of left margin (def: 0)
	"nodepage",	# Do not remove pagination lines
	"noheads",	# Do not detect for section heads
	"pgsize=i",	# Number of lines in a page (def: 66)
	"seealso",	# Link to other manpages only in the SEE ALSO section
	"solaris",	# Parse 'man -k' output from a solaris system
	"sun",		# Section heads are not overstriked in input
	"title=s",	# Title of manpage (def: Not defined)
	"topm=i",	# Number of lines for top margin (def: 7)
	"uelem=s",	# HTML Element for underlined text (def: "I")

	"help"		# Short usage message
    );
    return 0  if defined($opt_help);

    $pgsz = $opt_pgsize || $pgsz;
    if (defined($opt_nodepage)) {
	$hdsz   = 0;
	$ftsz   = 0;
    } else {
	$hdsz   = $opt_topm  if defined($opt_topm);
	$ftsz   = $opt_botm  if defined($opt_botm);
    }
    $txsz       = $pgsz - ($hdsz + $ftsz);
    $leftmsz    = $opt_leftm  if defined($opt_leftm);
    $leftm      = ' ' x $leftmsz;

    $Bare       = defined($opt_bare);
    $Compress   = defined($opt_compress);
    $K          = defined($opt_k);
    $NoDepage   = defined($opt_nodepage);
    $NoHeads    = defined($opt_noheads);
    $SeeAlso    = defined($opt_seealso);
    $Solaris    = defined($opt_solaris);
    $Sun        = defined($opt_sun);

    $Title      = $opt_title || $Title;
    $CgiUrl     = $opt_cgiurlexp ||
			($opt_cgiurl ? qq{return "$opt_cgiurl"} : '');

    $BTag	= $opt_belem || $BTag;
    $UTag	= $opt_uelem || $UTag;
    $BTag	=~ s/[<>]//g;
    $UTag	=~ s/[<>]//g;

    if (defined($opt_headmap)) {
	require $opt_headmap or warn "Unable to read $opt_headmap\n";
    }
    1;
}

##---------------------------------------------------------------------------
sub printhead {
    print $OutFH "<HTML>\n";
    print $OutFH "<HEAD>\n",
		 "<TITLE>$Title</TITLE>\n",
		 "</HEAD>\n"  if $Title;
    print $OutFH "<BODY bgcolor=pink>\n";
    print $OutFH "<H1>$Title</H1>\n",
		 "<HR>\n"  if $Title;
}

##---------------------------------------------------------------------------
sub printtail {
    print $OutFH <<EndOfRef;
<HR>
<ADDRESS>
Man(1) output converted with
<a href="http://www.oac.uci.edu/indiv/ehood/man2html.html">man2html</a>
</ADDRESS>
</BODY>
</HTML>
EndOfRef
}

##---------------------------------------------------------------------------
sub emphasize {
    my($txt) = shift;
    $txt =~ s/.\010//go;
    $txt = "<$UTag>$txt</$UTag>";
    $txt;
}

##---------------------------------------------------------------------------
sub strongize {
    my($txt) = shift;
    $txt =~ s/.\010//go;
    $txt = "<$BTag>$txt</$BTag>";
    $txt;
}

##---------------------------------------------------------------------------
sub entitize {
    my($txt) = shift;

    ## Check for special characters in overstrike text ##
    $$txt =~ s/_\010\&/strike('_', '&')/geo;
    $$txt =~ s/_\010</strike('_', '<')/geo;
    $$txt =~ s/_\010>/strike('_', '>')/geo;

    $$txt =~ s/(\&\010)+\&/strike('&', '&')/geo;
    $$txt =~ s/(<\010)+</strike('<', '<')/geo;
    $$txt =~ s/(>\010)+>/strike('>', '>')/geo;

    ## Check for special characters in regular text.  Must be careful
    ## to check before/after character in expression because it might be
    ## a special character.
    $$txt =~ s/([^\010]\&[^\010])/htmlize2($1)/geo;
    $$txt =~ s/([^\010]<[^\010])/htmlize2($1)/geo;
    $$txt =~ s/([^\010]>[^\010])/htmlize2($1)/geo;
}

##---------------------------------------------------------------------------
##	escape special characters in a string, in-place
##
sub htmlize {
    my($str) = shift;
    $$str =~ s/&/\&amp;/g;
    $$str =~ s/</\&lt;/g;
    $$str =~ s/>/\&gt;/g;
    $$str;
}

##---------------------------------------------------------------------------
##	htmlize2() is used by entitize.
##
sub htmlize2 {
    my($str) = shift;
    $str =~ s/&/\&amp;/g;
    $str =~ s/</\&lt;/g;
    $str =~ s/>/\&gt;/g;
    $str;
}

##---------------------------------------------------------------------------
##	strike converts HTML special characters in overstriked text
##	into entity references.  The entities are overstriked so
##	strongize() and emphasize() will recognize the entity to be
##	wrapped in tags.
##
sub strike {
    my($w, $char) = @_;
    my($ret);
    if ($w eq '_') {
	if ($char eq '&') {
	    $ret = "_$bs\&_${bs}a_${bs}m_${bs}p_${bs};";
	} elsif ($char eq '<') {
	    $ret = "_$bs\&_${bs}l_${bs}t_${bs};";
	} elsif ($char eq '>') {
	    $ret = "_$bs\&_${bs}g_${bs}t_${bs};";
	} else {
	    warn qq|Unrecognized character, "$char", passed to strike()\n|;
	}
    } else {
	if ($char eq '&') {
	    $ret = "\&$bs\&a${bs}am${bs}mp${bs}p;${bs};";
	} elsif ($char eq '<') {
	    $ret = "\&$bs\&l${bs}lt${bs}t;${bs};";
	} elsif ($char eq '>') {
	    $ret = "\&$bs\&g${bs}gt${bs}t;${bs};";
	} else {
	    warn qq|Unrecognized character, "$char", passed to strike()\n|;
	}
    }
    $ret;
}

##---------------------------------------------------------------------------
##	make_xref() converts a manpage crossreference into a hyperlink.
##
sub make_xref {
    my $str = shift;
    $str =~ s/.\010//go;			# Remove overstriking

    if ($CgiUrl) {
	my($title,$section,$subsection) =
	    ($str =~ /([\+_\.\w-]+)\((\d)(\w?)\)/);

	$title =~ s/\+/%2B/g;
	my($href) = (eval $CgiUrl);
	qq|<B><A HREF="$href">$str</A></B>|;
    } else {
	qq|<B>$str</B>|;
    }
}

##---------------------------------------------------------------------------
##	man_k() process a keyword search.  The problem we have is there
##	is no standard for keyword search results from man.  Solaris
##	systems have a different enough format to warrent dealing
##	with it as a special case.  For other cases, we try our best.
##	Unfortunately, there are some lines of results that may be
##	skipped.
##
sub man_k {
    my($line,$refs,$section,$subsection,$desc,$i,
       %Sec1, %Sec1sub, %Sec2, %Sec2sub, %Sec3, %Sec3sub,
       %Sec4, %Sec4sub, %Sec5, %Sec5sub, %Sec6, %Sec6sub,
       %Sec7, %Sec7sub, %Sec8, %Sec8sub, %Sec9, %Sec9sub,
       %SecN, %SecNsub, %SecNsec);

    printhead()  unless $Bare;
    print $OutFH "<!-- Man keyword results converted by ",
		      "man2html $VERSION -->\n";

    while ($line = <$InFH>) {
	next if $line !~ /\(\d\w?\)\s+-\s/; # check if line can be handled
	($refs,$section,$subsection,$desc) =
	    $line =~ /^\s*(.*)\((\d)(\w?)\)\s*-\s*(.*)$/;

	if ($Solaris) {
	    $refs =~ s/^\s*([\+_\.\w-]+)\s+([\+_\.\w-]+)\s*$/$1/;
					#  <topic> <manpage>
	} else {
	    $refs =~ s/\s(and|or)\s/,/gi; # Convert and/or to commas
	    $refs =~ s/^[^:\s]:\s*//;	# Remove prefixed whatis path
	}
	$refs =~ s/\s//g;		# Remove all whitespace
	$refs =~ s/,/, /g;		# Put space after comma
	htmlize(\$desc);		# Check for special chars in desc
	$desc =~ s/^(.)/\U$1/;		# Uppercase first letter in desc

	if ($section eq '1') {
	    $Sec1{$refs} = $desc; $Sec1sub{$refs} = $subsection;
	} elsif ($section eq '2') {
	    $Sec2{$refs} = $desc; $Sec2sub{$refs} = $subsection;
	} elsif ($section eq '3') {
	    $Sec3{$refs} = $desc; $Sec3sub{$refs} = $subsection;
	} elsif ($section eq '4') {
	    $Sec4{$refs} = $desc; $Sec4sub{$refs} = $subsection;
	} elsif ($section eq '5') {
	    $Sec5{$refs} = $desc; $Sec5sub{$refs} = $subsection;
	} elsif ($section eq '6') {
	    $Sec6{$refs} = $desc; $Sec6sub{$refs} = $subsection;
	} elsif ($section eq '7') {
	    $Sec7{$refs} = $desc; $Sec7sub{$refs} = $subsection;
	} elsif ($section eq '8') {
	    $Sec8{$refs} = $desc; $Sec8sub{$refs} = $subsection;
	} elsif ($section eq '9') {
	    $Sec9{$refs} = $desc; $Sec9sub{$refs} = $subsection;
	} else {			# Catch all
	    $SecN{$refs} = $desc; $SecNsec{$refs} = $section;
	    $SecNsub{$refs} = $subsection;
	}
    }
    print_mank_sec(\%Sec1, 1, \%Sec1sub);
    print_mank_sec(\%Sec2, 2, \%Sec2sub);
    print_mank_sec(\%Sec3, 3, \%Sec3sub);
    print_mank_sec(\%Sec4, 4, \%Sec4sub);
    print_mank_sec(\%Sec5, 5, \%Sec5sub);
    print_mank_sec(\%Sec6, 6, \%Sec6sub);
    print_mank_sec(\%Sec7, 7, \%Sec7sub);
    print_mank_sec(\%Sec8, 8, \%Sec8sub);
    print_mank_sec(\%Sec9, 9, \%Sec9sub);
    print_mank_sec(\%SecN, 'N', \%SecNsub, \%SecNsec);

    printtail()  unless $Bare;
}
##---------------------------------------------------------------------------
##	print_mank_sec() prints out manpage cross-refs of a specific section.
##
sub print_mank_sec {
    my($sec, $sect, $secsub, $secsec) = @_;
    my(@array, @refs, $href, $item, $title, $subsection, $i, $section,
       $xref);
    $section = $sect;

    @array = sort keys %$sec;
    if ($#array >= 0) {
	print $OutFH "<H2>Section $section</H2>\n",
		     "<DL COMPACT>\n";
	foreach $item (@array) {
	    @refs = split(/,/, $item);
	    $section = $secsec->{$item}  if $sect eq 'N';
	    $subsection = $secsub->{$item};
	    if ($CgiUrl) {
		($title = $refs[0]) =~ s/\(\)//g;  # watch out for extra ()'s
		$xref = eval $CgiUrl;
	    }
	    print $OutFH "<DT>\n";
	    $i = 0;
	    foreach (@refs) {
		if ($CgiUrl) {
		    print $OutFH qq|<B><A HREF="$xref">$_</A></B>|;
		} else {
		    print $OutFH $_;
		}
		print $OutFH ", "  if $i < $#refs;
		$i++;
	    }
	    print $OutFH " ($section$subsection)\n",
			 "</DT><DD>\n",
			 $sec->{$item}, "</DD>\n";
	}
	print $OutFH "</DL>\n";
    }
}

##---------------------------------------------------------------------------
##
sub usage {
    print $OutFH <<EndOfUsage;
Usage: $PROG [ options ] < infile > outfile
Options:
  -bare            : Do not put in HTML, HEAD, BODY tags
  -belem <elem>    : HTML Element for overstriked text (def: "B")
  -botm <#>        : Number of lines for bottom margin (def: 7)
  -cgiurl <url>    : URL for linking to other manpages
  -cgiurlexp <url> : Perl expression URL for linking to other manpages
  -compress        : Compress consective blank lines
  -headmap <file>  : Filename of user section head map file
  -help            : This message
  -k               : Process a keyword search result
  -leftm <#>       : Character width of left margin (def: 0)
  -nodepage        : Do not remove pagination lines
  -noheads         : Turn off section head detection
  -pgsize <#>      : Number of lines in a page (def: 66)
  -seealso         : Link to other manpages only in the SEE ALSO section
  -solaris         : Process keyword search result in Solaris format
  -sun             : Section heads are not overstriked in input
  -title <string>  : Title of manpage (def: Not defined)
  -topm <#>        : Number of lines for top margin (def: 7)
  -uelem <elem>    : HTML Element for underlined text (def: "I")

Description:
  $PROG takes formatted manpages from STDIN and converts it to HTML sent
  to STDOUT.  The -topm and -botm arguments are the number of lines to the
  main body text and NOT to the running headers/footers.

Version:
  $VERSION
  Copyright (C) 1995-1997  Earl Hood, ehood\@medusa.acs.uci.edu
  $PROG comes with ABSOLUTELY NO WARRANTY and $PROG may be copied only
  under the terms of the GNU General Public License, which may be found in
  the $PROG distribution.

EndOfUsage
    exit 0;
}
