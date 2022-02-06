#!/usr/bin/python

r"""depends.py - find the dependencies of a library

To use this:
	depends.py <pathtolibrary>
	
"""

__author__	= "Robin Mills <robin@clanmills.com>"
__date__	= "$Date: 2008/04/04 $"
__version__	= "$Id: //depot/bin/gps.py#9 $"
__credits__	= """Everybody who contributed to Python.
Especially: Guido van Rossum for creating the language.
And: Mark Lutz for the O'Reilly Books to explain it.
And: Ka-Ping Yee for the wonderful module 'pydoc'.
"""

import string
import os
import sys

##
#
def depend(libname,dependdict,executable_path=False):
	""" recursive descent of the libraries """

	if os.path.islink(libname):
		libname=os.path.realpath(libname);
	loader_path=False
		
	print '------ libname =',libname,'---------'

	if os.path.isdir(libname):
		if libname[len(libname)-1]==os.path.sep:
			libname=libname[0:len(libname)-1]
		stub=os.path.basename(libname).split('.')[0]
		print "stub=",stub
		filename=os.path.abspath(os.path.join(libname,'Contents','MacOS',stub))
		print "filename",filename
		if not os.path.isfile(filename):
			stub=stub.replace(' ', '')
			print "stub=",stub
			filename=os.path.abspath(os.path.join(libname,'Contents','MacOS',stub))
			print "filename",filename
			
		if os.path.isfile(filename):
			libname=filename;

		if not os.path.isfile(libname):
			filename=os.path.abspath(os.path.join(libname,'Versions','Current',stub))
			print "filename",filename
			if not os.path.isfile(filename):
				stub=stub.replace(' ', '')
				print "stub=",stub
				filename=os.path.abspath(os.path.join(libname,'Versions','Current',stub))
				print "filename",filename

		if os.path.isfile(filename):
			libname=filename;

	if os.path.islink(libname):
		libname=os.path.realpath(libname);

	if not os.path.isfile(libname):
		print "*** error NOT a FILE ",libname," ***"
		exit(1)
	else:
		libname = os.path.realpath(libname)
		if not loader_path:
			loader_path = os.path.dirname(libname)
			
		if not executable_path:
			executable_path=loader_path
			
		if not dependdict.has_key(libname):
			dependdict[libname]=libname # result
			cmd = 'otool -L "%s"' % libname              # otool -L tells us the dependencies of this library
			executable_path=os.path.dirname(executable_path)

			for line in os.popen(cmd).readlines():       # run find command
				line = line.replace('@loader_path'    ,loader_path    ) 
				line = line.replace('@executable_path',executable_path) 

				if line.find(':')<0:
					mylist = line.split('(')
					if len(mylist) > 1:
						depend(mylist[0].strip(),dependdict,executable_path)

##
#
def NB(x):
	return x.replace(' ','_')
#
##

##
#
def UB(x):
	return x.replace('_',' ')
#
##

##
#
def tsort(dict):
	filename='/tmp/tsortXX.txt'
	file=open(filename,'w')
	for key in dict.keys():
		cmd = 'otool -L "%s"' % key		         		# otool -L tells us the dependencies of this library

		for line in os.popen(cmd).readlines():      # run find command
			mylist = string.split(line)
			if len(mylist) > 1:
				file.write('%s %s\n' % ( NB(key),NB(mylist[0]) ))
	file.close()
				
	bar = '-'*20
	print bar
	sys.stdout.flush()
	cmd='tsort "%s" 2>/dev/null' % (filename)
	# os.system(cmd)
	#print bar
	lines=os.popen(cmd).readlines()
	lines.reverse()	
	for line in lines:
		print UB(line),
	print
	print bar
#
##

##
#
def main(argv):
	""" main function of this program of course """
	dependdict = {}
	libname = argv[0]
	print "libname = ",libname
	depend(libname,dependdict)
	
	longest = 0
	for libname in dependdict.keys():
		if len(libname) > longest:
			longest = len(libname)

	longest += 1

	bPrint = False
	if bPrint:
		for libname in sorted(dependdict.keys()):
			# leave at least n spaces
			n = longest - len(libname)
			if n < 0:
				n = 0
			print libname,' '*n,dependdict[libname]
		
	tsort(dependdict)	
#
##

if __name__ == '__main__':
	main(sys.argv[1:])




##
# for file in os.popen(cmd).readlines():   # run find command
#   num  = 1
#   name = file[:-1]                       # strip '\n'
#   for line in open(name).readlines():    # scan the file
#       pos = string.find(line, "\t")
#       if  pos >= 0:
#           print name, num, pos           # report tab found
#           print '....', line[:-1]        # [:-1] strips final \n
#           print '....', ' '*pos + '*', '\n'
#       num = num+1
##

        