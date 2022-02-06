#!/usr/bin/env bash

# ++++++++++++++++++++++++++++
# Work in progress - not ready for production use
# ++++++++++++++++++++++++++++

# ----------------------------
# cm - wrapper script for CMake
# Syntax at bottom of script

Syntax() {
	echo usage: cm.sh [ clean \| unix \| xcode \| 2003 \| 2005 \| 2008 \| 2010 [64]]
	exit 1
}

# ----------------------------
# test command args
E=0
G=$1
X=$2

shift
shift

# ----------------------------
# figure out the generator (G)
if [ "$G" == "2003"  ]; then G="Visual Studio 7 .NET 2003" ; fi
if [ "$G" == "2005"  ]; then G="Visual Studio 8 2005" ; fi
if [ "$G" == "2008"  ]; then G="Visual Studio 9 2008" ; fi
if [ "$G" == "2010"  ]; then G="Visual Studio 10" ; fi
if [ "$G" == "unix"  ]; then G="Unix Makefiles" ; fi
if [ "$G" == "xcode" ]; then G="Xcode" ; fi
if [ "$X" == "64"    ]; then G="$G Win64" ; X= ; fi

if [ "$G" == "" ]; then Syntax ; fi

# ----------------------------
# Cleanup from last time
C=CMakeCache.txt
D=CMakeFiles
if [ -e $C ]; then rm     $C ; fi
if [ -e $D ]; then rm -rf $D ; fi

# ----------------------------
# really execute cmake
if [ "$G" != clean ]; then
	# echo -e "-----------------------------\n"
	echo cmake CMakeLists.txt -G "$G" "$X" "$@"
	     cmake CMakeLists.txt -G "$G" "$X" "$@"
fi

# That's all folks
##
