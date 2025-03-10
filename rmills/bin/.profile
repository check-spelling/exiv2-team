##
# prompt and bash magic

export HOST=`(hostname|cut -d. -f 1)`
# If id command returns zero, you’ve root access.
if [ "$USER" == "rootXXX" ]; then                # $(id -u) -eq 0 ];
    # you are root, set yellow color prompt
    # http://news.softpedia.com/news/How-to-Customize-the-Shell-Prompt-40033.shtml
    PS1="\\[\! $(tput setaf 3)\\]\\u@\\h:\\w #\\[$(tput sgr0)\\] "
fi

# export PS1='\! $(tput setaf 3)\u@\h:\w$(tput sgr0) $ '
if [ "$USER" == "rootYYY" ]; then
#   PS1="\\[\! $(tput setaf 2)\\]\\u@\\h:\\w $\\[$(tput sgr0)\\] "
    PS1='\! $(tput setaf 2)\u@\h:\w$(tput sgr0) # '
fi

# http://wiki.bash-hackers.org/scripting/debuggingtips
export PS1='\! \u@\h:\w \$ '
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# increase the number of open files
# 516 /Users/rmills/clanmills $ ulimit -a
# core file size          (blocks, -c) 0
# data seg size           (kbytes, -d) unlimited
# file size               (blocks, -f) unlimited
# max locked memory       (kbytes, -l) unlimited
# max memory size         (kbytes, -m) unlimited
# open files                      (-n) 256
# pipe size               (512 bytes, -p) 1
# stack size              (kbytes, -s) 8192
# cpu time                (seconds, -t) unlimited
# max user processes              (-u) 709
# virtual memory          (kbytes, -v) unlimited
# 517 /Users/rmills/clanmills $
ulimit -n 1024

##
# environment strings
BIN=${HOME}/bin

export PLATFORM=''
if [ `uname` == Darwin  ]; then
    PLATFORM=macosx
    alias unq='xattr -d com.apple.quarantine'
elif [ `uname -o` == Cygwin ]; then
    PLATFORM=cygwin
elif [ `uname -o` == Msys ]; then
    PLATFORM=mingw
else
    PLATFORM=linux
fi

export FACTORY=$(hostname)

# export EBSREVISION=Dev
export CBL_STONEHENGE=1
export PATH=".:${BIN}:$BIN/$PLATFORM:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin:/usr/X11R6/bin:~/Library/Python/3.8/bi"
export MANPATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/share/man/:/usr/local/share/man:/usr/share/man:/usr/share/man/man1:/usr/share/man/man2:/usr/share/man/man3:/usr/local/man:/usr/local/share/man/:/usr/X11R6/man:/opt/local/share/man:/opt/subversion/man"
export DISPLAY=:0.0
export CLASSPATH=".:${HOME}/classpath:${HOME}/classpath/Multivalent20060102.jar:${HOME}/classpath/DVI20060102.jar"
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib/pkgconfig:/opt/local/lib/pkgconfig

##
# scripting support
# used by cpan
export "FTP_PASSIVE=1"

# export PYTHONPATH=~/scripts/:${HOME}/bin/:.:/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/site-packages
# export PYTHONPATH=/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/site-packages

export VERSIONER_PERL_PREFER_32_BIT=no
export VERSIONER_PYTHON_PREFER_32_BIT=no
export PERLPATH=/Users/rmills/gnu/ImageMagick
export PYTHONPATH="/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/site-packages:$PYTHONPATH"
export RUBYOPT=rubygems
if [ ! -z $PERL5LIB ]; then
    export PERL5LIB="$PERL5LIB:${BIN}"
else
    export PERL5LIB="${BIN}"
fi

##
# clanmills support
export REMOTEHOST=exiv2.dyndns.org # clanmills.homedns.org
export GPGKEY=CF1649DA

##
# photos
export PHOTOS="$HOME/Documents/Dropbox/Photos"
export QHOTOS="$PHOTOS/../../NotDropbox/Photos"
DropboxPhotos=/Volumes/Data/rmills/Dropbox/Photos
NotDropboxPhotos=/Volumes/Data/rmills/NotDropbox/Photos
if [ -e "$DropboxPhotos" ]; then
    export PHOTOS="$DropboxPhotos"
fi
if [ -e "$NotDropboxPhotos" ]; then
    export QHOTOS="$NotDropboxPhotos"
fi

##
# finder helpers
# export ARCHFLAGS="-arch x86_64" # "-arch i386 -arch ppc"
# export CFLAGS="$ARCHFLAGS"      # "-arch i386 -arch ppc"
# export LDFLAGS="$ARCHFLAGS"     # "-arch i386 -arch ppc"
export L="-exec ls -dalt {} ;"
export X="-exec rm -rf {} ;"
export C="-exec ce {} ;"
export I="-exec lipo -info {} ;"
export O="-exec otool -L {} ;"
export Z="-exec open {} ;"
export P="-exec p4 edit {} ;"
export R="-exec p4 revert {} ;"
export G="-exec grep"
export __=";"
export ___="{} ;"

##
# Install image magick
# http://mirror1.smudge-it.co.uk/imagemagick/www/binary-releases.html#macosx
# export MAGICK_HOME="/Users/rmills/gnu/ImageMagick"
# export PATH="$MAGICK_HOME:$PATH"
# export DYLD_LIBRARY_PATH="$MAGICK_HOME/lib:$DYLD_LIBRARY_PATH"

##
# functions
dir() {
    list='ls -dlthpF'
    if [ ${#*} -eq 0 ]; then
        $list *
    elif [ ${#*} -eq 1 ]; then
        if [ -d "$1" ]; then
#           (pushd "$1">/dev/null;$list *)
            if [ "$1" == '.' ]; then
                $list
            else
                $list $(dirname "$1")/$(basename "$1")/*
            fi
        elif [ "$1" = /od ]; then
            shift
            eval dirod $*
        elif [ "$1" = /os ]; then
            shift
            eval diros $*
        else
            $list "$@"
        fi
    else
        $list "$@"
    fi
}

renew() {
	base=$(basename $PWD)
	cd ..
	rm -rf $base
	mkdir  $base
	cd     $base
}

# http://askubuntu.com/questions/21657/show-apt-get-installed-packages-history-via-commandline
### apt-history [install | remove | rollback]
function apt-history(){
	if [ $# != 1 ]; then
		echo "syntax: apt-history [ install | remove | rollback ]"
	else
        case "$1" in
            install)
                cat /var/log/dpkg.log | grep 'install '
                ;;
            upgrade|remove)
                cat /var/log/dpkg.log | grep $1
                ;;

            rollback)
                cat /var/log/dpkg.log | grep upgrade | \
                    grep "$2" -A10000000 | \
                    grep "$3" -B10000000 | \
                    awk '{print $4"="$5}'
                ;;

            *)
                cat /var/log/dpkg.log
                ;;
        esac
    fi
}

killmail() {
	echo $'del *\nq' | mail
}

thepath() {
    if [ -d $1 ]; then
    	(cd $1 ; pwd)
    else
    	(cd $(dirname $1) ;echo $(pwd)/$(basename $1))
    fi
}

export HISTTIMEFORMAT="%T "
history() {
    builtin history | tail -30
}

free() {
    df -h .
#   df -k . | tail -1 | cut -f4 -d ' '
}

dirs() {
    ls -ltpF $1 | grep "^d"
}

links() {
    ls -altpF $1 | grep "^l"
    #
    # for x in `(ls -F|grep @)`; do echo "${x::${#x}-1}" ; done
}

files() {
    ls -altpF $1 | grep "^-"
}

socks() {
    ls -altpF $1 | grep "^s"
}


diros() {
    ls -lt $* | sort --key=5 --numeric-sort
#   ls -ltFp $* | tigersort +4 -n
}

diron() {
    ls -lt  $* | sort --key=9 --ignore-case
#   ls -ltp $* | tigersort +8 -i
}

hidden() {
    ls -altpF $1 | grep " \."
}

crdir() {
    dir="$@"
    if [ $# -eq 1 ]; then
        mkdir "$@"
        cd    "$@"
    elif [ $# -eq 0 ]; then
        echo "*** give me an argument,buddy ***"
    else
        echo "*** too many arguments ***"
    fi
}
alias crd=crdir

to() {
    ##
    # parse the arguments
    target=""
    error=0
    cd=0
    help=0
    verbose=0
    parse=1
    args=()
    for arg in "$@" ; do
        target="$arg"
        if [ $parse == 1 ]; then
            # to lower case if more than 2 characters
            if [ "${#arg}" -gt 2 ]; then
                arg="$(echo $arg|perl -e 'print lc <>;')"
            fi
            case "$arg" in
              -n|--nocd)     cd=0       ;;
              -c|--cd)       cd=1       ;;
              -v|--verbose)  verbose=1  ;;
             -\?|--help|-h)  help=1     ;;
              --)            parse=0    ;;
              *)             parse=0    ; args+=("$target") ;;
            esac
        else
            args+=("$target")
        fi
    done

    ##
    # report or bail
    if [ ${#args} == 0 ]; then help=1; fi
    if [ $help == 1 ]; then
        echo "to [--[no]cd --help --verbose --] [command ...] filename"
        error=1
    fi
    if [ $error == 1 ]; then return; fi

    unset args[${#args[@]}-1]
    argc=${#args}
    if [ $verbose == 1 ]; then
        echo args   = ${args[@]} "(argc = $argc)"
        echo target = "$target" ;
        echo cd     =  $cd
    fi

    ##
    # pain over.  find possible targets
    tmp=/tmp/2.tmp
    find . -name "$target" -print > $tmp
    # count=$(wc -l $tmp | rev | sed -e "s/.* //" | rev)
    declare -i count=0
    for i in $(cat $tmp); do : $((count++));done

    if [ "$count" == "1" ]; then
        dir=$(cat "$tmp")
        dir=$(dirname "$dir")
        if [ $argc -gt 0 ]; then
            if [ $cd == 1 ]; then
                pushd "$dir"  >/dev/null
                echo "$" cd "$dir" ";" "${args[@]}" "$target"
                find . -name "$target" -print0 | xargs -0 "${args[@]}"
                popd >/dev/null
            else
                echo ">" "${args[@]}" "$dir/$target"
                find . -name "$target" -print0 | xargs -0 "${args[@]}"
            fi
        elif [ $argc -eq 0 ]; then
            if [ -d "$dir/$target" ]; then
                dir="$dir/$target"
            fi
            echo $ cd "$dir"
            cd "$dir"
        fi
    elif [ "$count" == "0" ]; then
        echo "*** NO file found ***"
    else
        echo "*** TOO Many files found ***"
        cat $tmp
    fi
}
alias 2=to

path() {
    if [ -d $1 ]; then
    	(cd $1 ; pwd)
    else
    	(cd $(dirname $1) ;echo $(pwd)/$(basename $1))
    fi
}


# catch all - use good old vi!
#if [ -z "$CE" ]; then
#   export CE=vi
#fi

##
# aliases
# dos like things
alias rename=mv
alias move=mv
alias del='sudo rm -rf'
alias dirod='ls -ltr'
alias xcopy='ditto'
alias finder='find . -depth -iname'
alias shellx=open
alias start=open
alias get=git
alias p4s='. p4.so'
if [ -e /opt/local/bin/svn ]; then
	alias svn18=/opt/local/bin/svn
fi

if [ $PLATFORM == linux ]; then
    alias open=xdg-open
    alias shellx=open
    alias start=open

    J=/usr/local/java/jdk1.7.0_51
    if [ -d /usr/local/java/jdk.1.7.0_21    ]; then J=/usr/local/java/jdk1.7.0_21 ; fi
    if [ -d ~/Software/Java/jre1.8.0_25     ]; then J=~/Software/Java/jre1.8.0_25 ; fi
    if [ -d ~/Software/Java/jdk1.8.0_25     ]; then J=~/Software/Java/jdk1.8.0_25 ; fi
    export JAVA_HOME=$J
    export PATH=$PATH:$HOME/bin:$JAVA_HOME/bin

    if [ -z "$LD_LIBRARY_PATH" ]; then export LD_LIBRARY_PATH=/usr/local/lib
    else                               export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib"
    fi

    # JRE_HOME=/usr/local/java/jre1.7.0_21
    # PATH=$PATH:$HOME/bin:$JRE_HOME/bin
fi

if [ $PLATFORM == macosx ]; then
	function smartdiff()
	{
		"/Applications/SmartSynchronize 3.3.app/Contents/MacOS/SmartSynchronize" "$@" &
	}
fi

if [ $PLATFORM == mingw ]; then
	if [ ! -z "$MINGW_PREFIX" ]; then
		if [ -e "$MINGW_PREFIX" ]; then
			PATH="$MINGW_PREFIX/bin:$PATH"
		fi
	fi
fi

# hieroglyphics
alias ..='cd ..'
alias ...=sudo
alias ~='cd ~'
alias plugins='cd ~/Library/Application\ Support/eTeks/Sweet\ Home\ 3D/plugins'
alias toweb='cd ~/gnu/SH3D/ToWebPlugin'

# one-liners
alias ridLeadingSpace="pbpaste | perl -e 'while(<>){\$_=~s/^\s*//g;print(\$_);}' | pbcopy "

# favorite directories
year=$(date "+%Y")
alias homepages="cd ~/clanmills/Homepages/$year"
alias photos="cd ~/Pictures/Photos/$year"
alias heather='cd ~/heather/httpdocs'
alias clanmills='cd ~/clanmills'
alias collages='cd ~/Pictures/Picasa/Collages'
alias tuts='cd ~/Projects/cocoatutorials'
alias QtSee='cd ~/Projects/cocoatutorials/QtSee'
alias robin='cd ~/Projects/cocoatutorials/robin'
alias HH='cd ~/Desktop/Stuff/HH'
alias PP='cd ~/Desktop/Stuff/PP'

#
# Favorite servers
ssh-add
alias clanmills.com='ssh clanmil1@clanmills.com'
alias rmillsmm='ssh rmillsmm'

##
# apache-maven (and itext support)
# http://maven.apache.org/download.html
# export M2_HOME=/usr/local/apache-maven/apache-maven-3.0.3
# export M2=$M2_HOME/bin
# export PATH=$M2:$PATH
# export MAVEN_OPTS="-Xms256m -Xmx512m"

##
# run the local kdiff3 type tool
differ () {
	declare -a args
	for arg in "$@"; do
		if [ -e $arg ]; then
			args+=("$arg")
		fi
		shift
	done
	cmd=kdiff3
	if [ "$PLATFORM" == "macosx" ]; then
		cmd=opendiff
	fi
	echo $cmd ${args[*]}
	     $cmd ${args[*]} &
}

export EXIV2HOME=~/gnu/github/exiv2/0.27-maintenance
export EXIV2WEB=~/gnu/exiv2/team/website
export EXIV2BUILDS=/Users/Shared/Jenkins/Home/userContent/builds/all
export EXIV2BUILDER=~/gnu/exiv2/team/contrib/buildserver
alias web='cd ${EXIV2WEB}'
alias home='cd ${EXIV2HOME}'
alias builds='cd ${EXIV2BUILDS}'
alias builder='cd ${EXIV2BUILDER}'
alias testfiles='cd /Users/Shared/Jenkins/Home/userContent/testfiles'
alias book='cd ~/gnu/exiv2/team/book'
alias bmff='cd ~/gnu/github/exiv2/bmff'

##
# platform adjustments
if [ "$PLATFORM" == "cygwin" ]; then
    d=$(find /c/boost -maxdepth 1 -type d -name "boo*" | sort | tail -1)
    if [ -d "$d" ]; then
        export "BOOST_ROOT=$d"
    fi
fi

if [ "$PLATFORM" == "macosx" ]; then
    : export DYLD_LIBRARY_PATH=/Users/rmills/boost_1_48_0/stage/lib:/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/site-packages
    # export DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH}:/opt/local/lib/"
    PATH="$PATH:/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin"
fi

if [ "$FACTORY" == "rmills-ubuntu" ]; then
    export PHOTOS=/Windows/Users/rmills/Documents/Dropbox/Photos
    export QHOTOS=/Windows/Users/rmills/Documents/Dropbox/Photos
    unset dir
fi

##
# last minute adjustments for different machines
if [ "$FACTORY" == "rmills-imac" ]; then
    export "PATH=/opt/subversion/bin:$PATH"
fi

if [ "$PLATFORM" == "macosx" ]; then
  	alias xce='open -a /Applications/Xcode.app'

	pushd / >/dev/null
		# turn off local backup in time machine
		# https://discussions.apple.com/message/21716617#21716617
		# https://discussions.apple.com/thread/3233868
		if [ -e .MobileBackups.trash ]; then
  			sudo chmod -Rf 777 .MobileBackups.trash
  			sudo rm -rf .MobileBackups.trash
  		fi
  		# tmutil = Time Machine Util ; pmset = Power Management Settings ;
  		# sudo tmutil disablelocal
  	popd >/dev/null

  	alias locate_update="sudo /usr/libexec/locate.updatedb &"

    # http://alvinalexander.com/mac-os-x/mac-os-x-10.9-wont-shut-down-slow-shutdown-solution
    # sudo defaults write /System/Library/LaunchDaemons/com.apple.securityd ExitTimeOut -int 5
    # sudo defaults write /System/Library/LaunchDaemons/com.apple.mDNSResponder ExitTimeOut -int 5
    # sudo defaults write /System/Library/LaunchDaemons/com.apple.diskarbitrationd ExitTimeOut -int 5
    # sudo defaults write /System/Library/LaunchDaemons/com.apple.coreservices.appleevents ExitTimeOut -int 5
    # sudo defaults write /System/Library/LaunchAgents/com.apple.coreservices.appleid.authentication ExitTimeOut -int 5

    if [ "$FACTORY" == "rmillsmm.local" ]; then
    	sudo chown jenkins /var/log/jenkins/jenk*
    fi

fi

if [ "$PLATFORM" == "mingw" ]; then
	PATH="/mingw/bin:$PATH:/c/Users/rmills/com:/c/Users/rmills/bin"
	alias kate=ce
fi

if [ "$PLATFORM" == "linux" ]; then
	if [ -e /usr/local/bin/svn ]; then
  		alias svn='/usr/local/bin/svn'
  	fi
  	# export "LDFLAGS=-W1,—no-keep-memory"
  	alias locate_update="sudo /usr/bin/updatedb &"
  	PATH="$PATH:$HOME/Software"
fi

export CS_HOME=$HOME/copperspice/

themes=/cygdrive/c/Users/rmills/AppData/Local/Microsoft/BingDesktop/themes/
if [ -e $themes ]; then
    (cp ${themes}/*.jpg /cygdrive/z/Users/rmills/clanmills/files/themes/ 2>/dev/null >/dev/null)
fi

cd ~/

export BOOST_ROOT=/Users/rmills/gnu/boost/boost_1_66_0
export BOOST_LIBRARYDIR=$BOOST_ROOT/libs
if [ -z "$DYLD_LIBRARY_PATH" ]; then
	export DYLD_LIBRARY_PATH=$BOOST_ROOT
else
	export "DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$BOOST_ROOT"
fi

# http://gitimmersion.com/lab_11.html
alias gs='git status '
alias ga='git add '
alias gb='git branch '
alias gc='git commit'
alias gd='git diff'
alias go='git checkout '
alias gk='gitk --all&'
alias gx='gitx --all'
alias z='xattr -d com.apple.quarantine'

alias got='git '
alias get='git '
# That's all Folks!
##

##
# One last thing:
##

## rmills - I've put /opt/local/bin at the end of the path to prevent Macports from putting his commands in front of the system's
# MacPorts Installer addition on 2011-12-06_at_12:29:07: adding an appropriate PATH variable for use with MacPorts.
export PATH=$PATH:/opt/local/bin:/opt/local/sbin:/opt/pkgconfig/bin
# Finished adapting your PATH environment variable for use with MacPorts.

##
# Your previous /Users/rmills/.profile file was backed up as /Users/rmills/.profile.macports-saved_2015-03-03_at_15:44:56
##

# MacPorts Installer addition on 2015-03-03_at_15:44:56: adding an appropriate PATH variable for use with MacPorts.
# export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
# Finished adapting your PATH environment variable for use with MacPorts.

export PATH="~/Library/Python/3.8/bin:/usr/local/opt/gettext/bin:$PATH"
