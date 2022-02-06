#!/usr/bin/env bash

syntax() {
    echo "usage: ./build.sh  { --help | -? | -h | platform  | switch | option     | location value }+ "
    echo ""
    echo "platform:    all[32] | msvc[32] | linux[32]  | macos      | cygwin | mingw | unix | freebsd | netbsd | solaris"
    echo "switch:     --source | --debug  | --static   | --shared   | --clang        | --background"
    echo "options:   --[no]nls | --video  | --asan     | --status   | --[no]unit     | --[no]publish | --[no]webready | --unicode"
    echo "msvc:         --2019 | --2017   | --2015     | --2013     | --2012         | --2010  | --2008"
    echo "location: --server B | --user C | --builds D | --cpp  {98 | 11 | 14 | 17}  | --stamp stamp " 
    echo "           --github {rmillsmm,github,E}      | {--tag tag | --branch branch}"
}

announce()
{
    if [ "$status" != "1" ]; then
        compiler=''
        options=''
        if [ $clang    == 1 ]; then compiler=Clang ; fi
        if [ $video    == 1 ]; then options="${options}Video "    ; fi
        if [ $webready == 1 ]; then options="${options}Webready " ; fi
        echo ++++++++++++++++++++++++++++++++
        echo $* ${compiler}${config}${library_type} ${options} ${branch}
        echo ++++++++++++++++++++++++++++++++
    fi
}

bomb() {
    echo "*** $1 requires an argument ***" >&2
    exit 1
}

# write stamp into the build directory (in Unix format without \r)
writeStamp()
{
    # $1 = server name (eg rmillsmm-w10)
    # $2 = command for ssh (eg msys64 or bash)
    # $3 = destination of stamp
    # $4 = stamp
    echo "echo stamp=$4 > $3" | ssh  -o ConnectTimeout=30 ${user}@$1 $2
}

# list the current build
reportStatus()
{
    # $1 = server (eg rmillsmm-w10)
    # $2 = program to run (eg msys64 or bash)
    # $3 = string to execute (eg cd .../buildserver/build ; ls -alt *.tar *.zip)
    echo "$3" | ssh -o ConnectTimeout=30 ${user}@$1 $2
}

unixBuild()
{
    # $1 = server                   (eg rmillsmm-w10)
    # $2 = string for announcement  (eg 'MinGW 64' )
    announce  $1 $2
    if [ "$status" == "1" ]; then
        reportStatus $1 $command "cd ${cd}/buildserver/build; ls -alt *.tar.gz | sed -e 's/\+ / /g'"
    else
        CLANG=""
        if [ $clang == 1 ]; then CLANG='echo "using Clang";export CC=$(which clang);export CXX=$(which clang++)' ; fi
        ! ssh -o ConnectTimeout=30 ${user}@$1 ${command} <<EOF
PATH="/usr/local/bin/:/usr/bin:/mingw64/bin:/usr/pkg/bin/:/usr/pkg/sbin:$PATH"
cd ${cd}
${CLANG}

echo ---- $(uname -a) --------
pwd
ls -l
if [ -e buildserver ]; then
    rm -rf buildserver
fi
echo git clone --branch $branch $github buildserver --depth 1
     git clone --branch $branch $github buildserver --depth 1
if [ ! -d buildserver ]; then
   echo "***"
   echo "***" no directory buildserver "***"
   echo "***"
   exit 1
fi
cd  buildserver
git status
if [ ! -z ${tag} ]; then 
    git fetch --unshallow
    git checkout ${tag} 
fi
rm    -rf build
mkdir -p  build
cd        build
rm    -rf logs
mkdir -p  logs
echo Build Directory $PWD                                                  2>&1 | tee -a logs/build.txt
git status                                                                 2>&1 | tee -a logs/build.txt
uname -a                                                                   2>&1 | tee -a logs/build.txt
export                                                                     2>&1 | tee -a logs/build.txt
echo cmake .. -G "Unix Makefiles" -DEXIV2_TEAM_PACKAGING=On -DBUILD_SHARED_LIBS=${shared} -DEXIV2_BUILD_UNIT_TESTS=${unit} -DEXIV2_TEAM_USE_SANITIZERS=${asan} -DEXIV2_ENABLE_VIDEO=${video} -DEXIV2_ENABLE_BMFF=${bmff} -DEXIV2_ENABLE_WEBREADY=${webready} -DEXIV2_ENABLE_SSH=0 -DEXIV2_ENABLE_CURL=${webready} -DEXIV2_ENABLE_NLS=$nls -DCMAKE_BUILD_TYPE=${config} -DCMAKE_CXX_STANDARD=${cpp} -DCMAKE_CXX_FLAGS=-Wno-deprecated -DEXIV2_ENABLE_WIN_UNICODE=${unicode} 2>&1 | tee -a logs/build.txt
     cmake .. -G "Unix Makefiles" -DEXIV2_TEAM_PACKAGING=On -DBUILD_SHARED_LIBS=${shared} -DEXIV2_BUILD_UNIT_TESTS=${unit} -DEXIV2_TEAM_USE_SANITIZERS=${asan} -DEXIV2_ENABLE_VIDEO=${video} -DEXIV2_ENABLE_BMFF=${bmff} -DEXIV2_ENABLE_WEBREADY=${webready} -DEXIV2_ENABLE_SSH=0 -DEXIV2_ENABLE_CURL=${webready} -DEXIV2_ENABLE_NLS=$nls -DCMAKE_BUILD_TYPE=${config} -DCMAKE_CXX_STANDARD=${cpp} -DCMAKE_CXX_FLAGS=-Wno-deprecated -DEXIV2_ENABLE_WIN_UNICODE=${unicode} 2>&1 | tee -a logs/build.txt
echo ---- git status ; git status
if [ "$source" == "0" ]; then
    make                                                                   2>&1 | tee -a logs/build.txt
    echo ---- git status ; git status
    ls -alt bin                                                            2>&1 | tee -a logs/build.txt
    make tests                                                             2>&1 | tee -a logs/build.txt
    make package
else
    make package_source
fi
ls -alt *.tar.gz | sed -e 's/\+ / /g'           2>&1 | tee -a logs/test.txt
EOF
        writeStamp $1 $command ${cd}buildserver/build/stamp $stamp
    fi
}

msvcBuild()
{
    # $1 = server                   (eg rmillsmm-w10)
    cd=c:\\Users\\rmills\\gnu\\github\\exiv2\\

    case "$edition" in
      2019) generator='Visual Studio 16 2019' ; bits='' ;;
      2017) generator='Visual Studio 15 2017' ;;
      2015) generator='Visual Studio 14 2015' ;;
      2013) generator='Visual Studio 12 2013' ;;
      2012) generator='Visual Studio 11 2012' ;;
      2010) generator='Visual Studio 10 2010' ;;
      2008) generator='Visual Studio 9 2008'  ;;
    esac
    profile=msvc${edition}${config}${bits}

    if [ "$bits" == "64" ]; then
         generator="${generator} Win64"
    fi
    generator="\"${generator}\""
    announce  $1 ${profile}

    if [ "$status" == "1" ]; then
        reportStatus $1 msys64 "cd ${cd}\\buildserver\\build ; ls -alt *.zip | sed -e 's/\+ / /g'"
    else
        ! ssh -o ConnectTimeout=30 ${user}@$1 cmd64 <<EOF
setlocal
cd ${cd}
python -c "import platform;print(platform.uname())"
@echo off
IF EXIST buildserver rmdir/s/q buildserver
git clone --branch ${branch} $github buildserver --depth 1
@echo on
cd buildserver
git status
set TAG=${tag}
if "%TAG%" NEQ "" ( git fetch     --unshallow ) 
if "%TAG%" NEQ "" ( git checkout  %TAG%       ) 
if     EXIST build rmdir/s/q build
if NOT EXIST build mkdir build
cd           build
if     EXIST logs  rmdir/s/q logs
mkdir logs
echo  log for $stamp                                                                   2>&1 | c:\msys64\usr\bin\tee -a logs\build.txt
python -c "import platform;print(platform.uname())"                                    2>&1 | c:\msys64\usr\bin\tee -a logs\build.txt
set                                                                                    2>&1 | c:\msys64\usr\bin\tee -a logs\build.txt
conan install .. --profile ${profile} --options webready=${webready} --build missing   2>&1 | c:\msys64\usr\bin\tee -a logs\build.txt
rem Always use -DEXIV2_ENABLE_DYNAMIC_RUNTIME=1 for MSVC builds (to evade expat __imp__mbspbrk linking issue)
rem Always use -DEXIV2_ENABLE_WIN_UNICODE=1 for MSVC builds (#1996)
echo cmake         .. -G ${generator} -DCMAKE_BUILD_TYPE=${config} -DEXIV2_ENABLE_BMFF=${bmff} -DEXIV2_ENABLE_DYNAMIC_RUNTIME=1 -DBUILD_SHARED_LIBS=${shared} -DEXIV2_ENABLE_WEBREADY=${webready} -DEXIV2_ENABLE_SSH=0 -DEXIV2_ENABLE_CURL=${webready} -DEXIV2_BUILD_UNIT_TESTS=${unit} -DEXIV2_ENABLE_VIDEO=${video} -DEXIV2_TEAM_PACKAGING=On -DCMAKE_INSTALL_PREFIX=..\dist\${profile} -DEXIV2_ENABLE_WIN_UNICODE=1 -DCMAKE_CXX_STANDARD=${cpp} 2>&1 | c:\msys64\usr\bin\tee -a  logs\build.txt
     cmake         .. -G ${generator} -DCMAKE_BUILD_TYPE=${config} -DEXIV2_ENABLE_BMFF=${bmff} -DEXIV2_ENABLE_DYNAMIC_RUNTIME=1 -DBUILD_SHARED_LIBS=${shared} -DEXIV2_ENABLE_WEBREADY=${webready} -DEXIV2_ENABLE_SSH=0 -DEXIV2_ENABLE_CURL=${webready} -DEXIV2_BUILD_UNIT_TESTS=${unit} -DEXIV2_ENABLE_VIDEO=${video} -DEXIV2_TEAM_PACKAGING=On -DCMAKE_INSTALL_PREFIX=..\dist\${profile} -DEXIV2_ENABLE_WIN_UNICODE=1 -DCMAKE_CXX_STANDARD=${cpp} 2>&1 | c:\msys64\usr\bin\tee -a  logs\build.txt
if %ERRORLEVEL% NEQ 0 exit 1
cmake --build .  --config ${config}                                                    2>&1 | c:\msys64\usr\bin\sed -e "s/^  //" | c:\msys64\usr\bin\tee -a logs\build.txt
if %ERRORLEVEL% NEQ 0 exit 2
SETLOCAL
set   EXIV2_EXT=.exe
set   PATH=c:\Python37;C:\Python37\Scripts;c:\Program Files\cmake\bin;c:\msys64\usr\bin;%PATH%;
cmake --build . --config ${config}  --target tests                                     2>&1 | c:\msys64\usr\bin\sed -e "s/^  //" | c:\msys64\usr\bin\tee -a  %EXIV2_BINDIR%\..\logs\build.txt
if    NOT %ERRORLEVEL% 1 set RESULT=ignored
ENDLOCAL
cmake --build .  --config ${config} --target package
exit  0
EOF
        writeStamp $1 msys64 ${cd}buildserver\\build\\stamp stamp
    fi
}

##
# assign defaults
this="$0"
all=0
all32=0
asan=0
background=0
bmff=0
branch=0.27-maintenance
builds=/Users/Shared/Jenkins/Home/userContent/builds
categorize=0
clang=0
config=Release
cpp=98
cygwin=0
cygwin32=0
freebsd=0
help=0
linux=0
linux32=0
macos=0
github=github
mingw=0
mingw32=0
msvc=0
msvc32=0
netbsd=0
nls=1
publish=1
server=$(hostname|cut -d. -f 1|cut -d- -f 1)
shared=1
solaris=0
source=0
status=0
unicode=0
unit=True
unix=0
user=$(whoami)
video=0
webready=False
stamp=$(date '+%Y-%m-%d_%H:%M:00')

if [ "$#" == "0" ]; then help=1; fi
##
# parse command line
while [ "$#" != "0" ]; do
    arg="$1"
    shift
    case "$arg" in
      -h|--help|-\?) help=1       ;;
      all)          all=1;all32=0 ;;
      all32)        all=0;all32=1 ;;
      background)   background=1  ;;
      cygwin)       cygwin=1      ;;
      freebsd)      freebsd=1     ;;
      linux)        linux=1       ;;
      linux32)      linux32=1     ;;
      macos)        macos=1       ;;
      mingw)        mingw=1       ;;
      msvc)         msvc=1        ;;
      msvc32)       msvc32=1      ;;
      netbsd)       netbsd=1      ;;
      solaris)      solaris=1     ;;
      unix)         unix=1        ;;
      --asan)       asan=1        ;;
      --bmff)       bmff=1        ;;
      --categorize) categorize=1  ;;
      --clang)      clang=1       ;;
      --debug)      config=Debug  ;;
      --full)       full=1        ;;
      --nls)        nls=1         ;;
      --nonls)      nls=0         ;;
      --publish)    publish=1     ;;
      --nopublish)  publish=0     ;;
      --shared)     shared=1      ;;
      --source)     source=1      ;;
      --static)     shared=0      ;;
      --status)     status=1      ;;
      --unicode)    unicode=1     ;;
      --unit)       unit=True     ;;
      --nounit)     unit=False    ;;
      --video)      video=1       ;;
      --webready)   webready=True ;;
      --nowebready) webready=False;;
      --2008|2008)  editions="$editions 2008" ;;
      --2010|2010)  editions="$editions 2010" ;;
      --2012|2012)  editions="$editions 2012" ;;
      --2013|2013)  editions="$editions 2013" ;;
      --2015|2015)  editions="$editions 2015" ;;
      --2017|2017)  editions="$editions 2017" ;;
      --2019|2019)  editions="$editions 2019" ;;
      --branch)     if [ $# -gt 0 ]; then branch="$1"  ; shift; else bomb $arg ; fi ;;
      --builds)     if [ $# -gt 0 ]; then builds="$1"  ; shift; else bomb $arg ; fi ;;
      --cpp)        if [ $# -gt 0 ]; then cpp="$1"     ; shift; else bomb $arg ; fi ;;
      --github)     if [ $# -gt 0 ]; then github="$1"  ; shift; else bomb $arg ; fi ;;
      --server)     if [ $# -gt 0 ]; then server="$1"  ; shift; else bomb $arg ; fi ;;
      --stamp)      if [ $# -gt 0 ]; then stamp="$1"   ; shift; else bomb $arg ; fi ;;
      --tag)        if [ $# -gt 0 ]; then tag="$1"     ; shift; else bomb $arg ; fi ;;
      --user)       if [ $# -gt 0 ]; then user="$1"    ; shift; else bomb $arg ; fi ;;
      *)            echo "*** invalid option: $arg ***" 1>&2; help=1; ;;
    esac
done

if [ $asan == 1 ]; then
    debug=1
fi

if [ $help == 1 ]; then
    syntax;
    exit 0;
fi

if [ -z "$branch" -a -z "$tag" ]; then
    branch=0.27-maintenance
fi

if [ $github == github   ]; then github=https://github.com/exiv2/exiv2                        ; fi
if [ $github == rmillsmm ]; then github=rmills@rmillsmm:/Users/rmills/gnu/github/exiv2/github ; fi

if [ "$all" == "1" ]; then
    cygwin=1; linux=1; macos=1; mingw=1; msvc=1;
    unit=True;publish=1;
fi
if [ "$unix" == "1" ]; then
    solaris=1;freebsd=1;netbsd=1;
    unit=True;publish=1;
fi
if [ "$all32" == "1" ]; then
    linux32=1; msvc32=1;publish=1
fi
if [ ! -z "$editions" ] ; then
    if [ "$msvc32" == "0" ] ; then
        msvc=1
    fi
fi

if [ "$full" == "1" ]; then
	ssh=0
	video=0
	webready=True
	publish=1
fi

publishBundle()
{
    # $1 = server    (eg rmillsmm-w10)
    # $2 = command   (eg msys32)
    # $3 = path      (eg /c/msys32/home/rmills/gnu/github/exiv2/buildserver/build)
    # $4 = extension (eg tar.gz or zip)
    if [ $publish == 1 ]; then
		# find the build stamp left during the build
		stamp_saved=$stamp
		if [ -e stamp ]; then rm -rf stamp ; fi
		scp -q "$user@$1:$3/stamp" . 2>/dev/null                    # silently collect build stamp file
		if [ -e stamp ]; then source stamp; fi                      # and read it!

		# echo ++-- "ls -l $3/*$4"
		files=$(echo ls -1 $3/*$4 | ssh -o ConnectTimeout=30 $user@$1 $2 2>/dev/null)    # find the names of the bundles
		# echo +++ files = $files # after ssh $user@$1 $2 ls -1 $3/\*$4
		for file in $files; do
			# echo ++++++ '>'$file'<'
			if [ ! -z $file ]; then                                 # copy to builds/all and merge the stamp into the filename
				echo scp -pq "$user@$1:$file" $builds/all/$(basename $file $4)-$stamp$4
					 scp -pq "$user@$1:$file" $builds/all/$(basename $file $4)-$stamp$4 2>/dev/null
			fi
		done
		stamp=$stamp_saved
		$(dirname $this)/categorize.py  $builds
    fi
}

library_type=''
if [ $shared != 1 ]; then library_type=Static; fi

##
# perform builds
if [ $linux == 1 ]; then
    cd=/home/rmills/gnu/github/exiv2/
    command='bash'
    unixBuild     ${server}-ubuntu Linux64
    publishBundle ${server}-ubuntu           ${command}   /home/$user/gnu/github/exiv2/buildserver/build              '.tar.gz'
    if [ $publish == 1 ]; then
		# recursively build package_source
		if [ -z $tag ]; then
		   "$this" --source --stamp "$stamp" --branch   "$branch"   --github "$github" --publish
		else
		   "$this" --source --stamp "$stamp" --tag      "$tag"      --github "$github" --publish
		fi
	fi
fi
if [ $linux32 == 1 ]; then
    cd=/home/rmills/gnu/github/exiv2/
    command='bash'
    unixBuild     ${server}-ubuntu32 Linux32
    publishBundle ${server}-ubuntu32         ${command}   /home/$user/gnu/github/exiv2/buildserver/build              '.tar.gz'
fi

if [ $source == 1 ]; then
    cd=/home/rmills/gnu/github/exiv2/
    command='bash'
    unixBuild     ${server}-ubuntu Source
    publishBundle ${server}-ubuntu           ${command}   /home/$user/gnu/github/exiv2/buildserver/build               '.tar.gz'
fi

if [ $freebsd == 1 ]; then
    nls_saved=$nls;nls=0 # building nls corrupts po/nl.po on freebsd
    cd=/home/rmills/gnu/github/exiv2/
    command='bash'
    unixBuild     ${server}-freebsd FreeBSD
    publishBundle ${server}-freebsd          ${command}   /home/$user/gnu/github/exiv2/buildserver/build              '.tar.gz'
    nls=$nls_saved
fi
if [ $netbsd == 1 ]; then
    cd=/home/rmills/gnu/github/exiv2/
    command='bash'
    unixBuild     ${server}-netbsd NetBSD
    publishBundle ${server}-netbsd           ${command}   /home/$user/gnu/github/exiv2/buildserver/build              '.tar.gz'
fi
if [ $solaris == 1 ]; then
    nls_saved=$nls
    nls=0                  # gettest isn't installed on rmillsmm-solaris
    cd=/export/home/rmills/gnu/github/exiv2/
    command='bash'
    unixBuild     ${server}-solaris Solaris
    publishBundle ${server}-solaris          ${command}   /export/home/$user/gnu/github/exiv2/buildserver/build       '.tar.gz'
    nls=nls_saved
fi

clang=0  # clang is not supported on Cygwin/macOS/MinGW/msvc/FreeBSD/NetBSD/Solaris
if [ $macos == 1 ]; then
    cd=/Users/rmills/gnu/github/exiv2/
    command='bash'
    unixBuild         ${server} macOS
    publishBundle     ${server}                bash        /Users/$user/gnu/github/exiv2/buildserver/build            '.tar.gz'
fi

if [ "$msvc" == 1  -o "$msvc32" == 1 ]; then
    command='cmd64'
    bits=64
    if [ $msvc32 == 1 ]; then bits=32 ; fi
    if [ -z "$editions" ]; then editions="2019" ; fi
    for edition in $(for edition in $editions ; do printf %"s\n" $edition ; done | sort | uniq) ; do
        save_webready=$webready;save_unit=$unit;
        save_unicode=$unicode:unicode=1
        webready=False                                 # MSVC/curl is toxic
        if [ $edition -lt 2012 ]; then unit=False; fi
        msvcBuild     ${server}-w10
        publishBundle ${server}-w10            msys64      /c/Users/$user/gnu/github/exiv2/buildserver/build          '.zip'
        unit=$save_unit;webready=$save_webready;unicode=save_unicode;
    done
fi

if [ $cygwin == 1 ]; then
    cd=/home/rmills/gnu/github/exiv2/
    command='cygwin64'
    save_unit=$unit;unit=0;
    save_unicode=$unicode;unicode=0;
    unixBuild ${server}-w10 Cygwin/64
    publishBundle ${server}-w10                msys64      /c/cygwin64/home/$user/gnu/github/exiv2/buildserver/build  '.tar.gz'
    unit=$save_unit;unicode=save_unicode;
fi

if [ $mingw == 1 ]; then
    cd=/home/rmills/gnu/github/exiv2/
    command='msys64'
    save_unit=$unit;unit=0;
    save_unicode=$unicode;unicode=1;
    unixBuild         ${server}-w10 MinGW/64
    publishBundle     ${server}-w10            msys64      /c/msys64/home/$user/gnu/github/exiv2/buildserver/build     '.tar.gz'
    unit=$save_unit;unicode=save_unicode;
fi

# That's all Folks
##
