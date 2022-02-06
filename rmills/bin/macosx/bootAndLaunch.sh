#!/bin/bash

##
# reboot MacOS-X and launch a command once
#
syntax() {
	echo "usage: $0 --title title --log log [ {--help|-? | --cd dir |--verbose}]+ --args args"
}

syntaxError() {
	syntax
	exit 1
}

error() {
	echo $@ 2>&1
	exit 1
}

bomb() {
	echo "*** $1 requires an argument ***" 1>&2	
	exit 1
}

if [ "$EUID" != 0 ]; then error "ROOT privileges required to run $0" ; fi

tmp=/tmp/bootAndLaunch.txt
c="$PWD"

# http://mywiki.wooledge.org/BashFAQ/035
while true; do
    case "$1" in
      -h|--help|-\?) syntaxError; exit 0 ;;
      -v|--verbose)  v=1; shift ;;
      -c|--cd)      if [ $# -gt 1 ]; then  c=$2 ; shift 2 ; else bomb $1 ; fi ;;
      -t|--title)   if [ $# -gt 1 ]; then  t=$2 ; shift 2 ; else bomb $1 ; fi ;;
      -l|--log)     if [ $# -gt 1 ]; then  l=$2 ; shift 2 ; else bomb $1 ; fi ;;
      --)            shift; break;;
      --args)        shift; break;;
      -*)            echo "invalid option: $1" 1>&2; syntaxError; exit 1;;
      *)             break;;
    esac
done

if [ -z $l ]; then l=/var/log/$t.log    ; fi
if [ -z $t -o -z $l ]; then syntaxError ; fi

if [ "$#" == "0" ]; then syntaxError ; fi
command="$@"

# concat //'s and remove trailing /
c=$(echo "$c" | sed -Ee 's_//_/_g' -e 's_/$__g')

w=~/Library/LaunchAgents/${t}.plist
remove="" # "launchctl remove $t"
unload="launchctl unload -w $w"

grep ^#- $0 | sed -Ee 's_^#- __g'       \
            | sed -Ee "s_TITLE_${t}_g"  \
            | sed -Ee "s_CD_${c}_g"     \
            | sed -Ee "s_LOG_${l}_g"    \
            | sed -Ee "s_COMMAND_${command}_g" > $w
launchctl load -w "$w"
if [ -z $v ]; then
	shutdown -r now
else 
	cat $w
fi

# That's all Folks
##

# grep ^#- $0 | sed -e 's/^#-//g'

#- <?xml version="1.0" encoding="UTF-8"?>
#- <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
#- <plist version="1.0">
#- <dict>
#-  <key>StandardOutPath</key><string>LOG</string>
#-  <key>StandardErrorPath</key><string>LOG</string>
#- 	<key>KeepAlive</key><false/>
#- 	<key>Label</key><string>TITLE</string>
#- 	<key>RunAtLoad</key><true/>
#- 	<key>WorkingDirectory</key><string>CD</string>
#- 	<key>SessionCreate</key><true />
#- 
#- 	<key>ProgramArguments</key>
#- 	<array>
#- 		<string>/bin/bash</string>
#- 		<string>-c</string>
#- 		<string>COMMAND</string>
#- 	</array>
#- 
#- 	<key>EnvironmentVariables</key>
#- 	<dict>
#- 		<key>ACROBAT_BUILD_HOME</key>
#- 		<string>CD/../..</string>
#- 		<key>PWD</key>
#- 		<string>CD</string>
#- 	</dict>
#- 
#- </dict>
#- </plist>
#- 


