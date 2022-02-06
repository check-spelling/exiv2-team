#!/bin/sh
# Create download tables

basedir=.
version=$(cat $basedir/var/__version__)

table=__download_table__
buttons=__download_buttons__

statbin=~/gnu/coreutils/coreutils-8.25/src/stat
if [ -x $(command -v stat) ]; then
    statbin=$(command -v stat)
fi

rm -rf $basedir/var/$table
rm -rf $basedir/var/$buttons
rm -rf $basedir/var/$buttons.tmp

##
# clean up from last time and copy builds html/builds
if [ -e   $basedir/html/builds ]; then rm -rf $basedir/html/builds ; fi
mkdir -p  $basedir/html/builds

for P in $(ls -1 $basedir/builds/* | sort --ignore-case)
do
    # P = ./builds/exiv2-0.27.0.2-CYGWIN-2018:10:31_11:57:09.tar.gz
    if echo "$P" | grep .zip ; then ext=zip ; else ext=tar.gz ; fi
    platform=$(echo $P | cut -d- -f 3   | sed "s,.$ext,,") # CYGWIN
    S=$(       echo $P | cut -d- -f 1-3 | sed "s,.$ext,,") # ./builds/exiv2-0.27.0.2-CYGWIN
    stub=$(    echo $S | cut -d/ -f 3-  | sed "s,.$ext,,") # exiv2-0.27.0.2-CYGWIN
    p=$stub.$ext                          # exiv2-0.27.0.2-CYGWIN.tar.gz
	echo P = $P
	echo platform = $platform
	echo S = $S
	echo stub = $stub
	echo ext  = $ext
	echo p = $p

    cp    -p  $P  $basedir/html/builds/$p
	size=$(ls -la        html/builds/$p | sed -e 's#  # #g' | cut -d' ' -f 5)
	echo size = $size
	# Why is stat platform dependent?
	date=$($statbin -c "%y"  html/builds/$p | cut -d' ' -f 1-2 | cut -d: -f 1-2)
	checkSum=$(sha256sum html/builds/$p | cut -d' ' -f 1)

	echo "<tr>  \
            <td>Exiv2 v$version $platform</td> \
            <td><a href=\"builds/$p\">$p</a></td> \
            <td>$size</td> \
            <td class=\"text-nowrap\">$date</td> \
            <td>$checkSum</td> \
          </tr>"  >> $basedir/var/$table

	config="64 bit shared libraries"
	if [ "$platform"  = "Darwin"   ]; then platform="macOS"                  ; fi
	if [ "$platform"  = "MSVC"     ]; then platform="Visual Studio"; config="64 bit DLLs for<br>Visual Studio 2019"; fi
	if [ "$platform" != "Source"   ]; then
  	  echo "<tr><td>$platform<h3></td><td>$config</td> \
	        <td> \
	          <p3 class=\"text-center\"> \
                <a href=\"builds/$p\" class=\"btn btn-sm btn-success\"> \
	            <span class=\"glyphicon glyphicon-download-alt\" aria-hidden=\"true\"></span>&nbsp;$p \
	            </a> \
	         </p3> \
            </td></tr>" >> $basedir/var/$buttons.tmp
    fi
    echo
done
ls -l $basedir/html/builds/* | sort --key=9 --ignore-case
cat $basedir/var/$buttons.tmp | sort --ignore-case > $basedir/var/$buttons ; rm -rf $basedir/var/$buttons.tmp

# That's all Folks!
##
