#!/usr/bin/python
####################################################################################################
#
# LB_proxyMaker.py
# To create lower res proxies of your image files. 
# by LEO BAKER		leo@turboradness.com
#
####################################################################################################

ver = 2.1

import Image, os, sys, getopt
from os import path, sep

print "\n LB_proxyMaker_" + str(ver)

# Query format, make jpegs

def main():
	#The main function. This checks for the input options and arguments and runs all other functions.

	#try: 
	SHORT_ARGS = "htw1od:"
  	LONG_ARGS = [ "help", "type" , "web", "1k" ,"openFolder", "division=" ] 

	try:
		opts, args = getopt.gnu_getopt( sys.argv[ 1: ], SHORT_ARGS, LONG_ARGS )
	except getopt.GetoptError:
        	usage()
        	sys.exit(2)
        	
	proxyDivision = 0
	proxyFolder = 0
	maintain = 0
	webSize = 0
	oneK = 0
	openSesame = 0

	for o, a in opts:
		if o in ( "-h", "--help" ):
			helpSection()
			return 0
			
		elif o in ( "-t", "--type" ):
			maintain = 1
			
		elif o in ( "-w", "--web" ):				
			webSize = 1
			
		elif o in ( "-1", "--1k" ):
			oneK = 1
			
		elif o in ("-o", "--openFolder"):
			openSesame = 1
			
		elif o in ( "-d", "--division" ):
			proxyDivision = int(a)
			
	if (int(oneK) + int(webSize) > 1) or (int(oneK) + int(webSize) != 0 and int(proxyDivision) != 0):
		print "\n ERROR: you cannot use multiple res-target flags, you can only specify one. Read the help to clarify.\n\n"
		helpSection()
		sys.exit(-1)
			
	inputFilez = args
	if len(inputFilez) != 0: 
		absList = []
		for i in inputFilez:
			if os.path.isdir(i):
				proxyFolder = 1
				listedDir = os.listdir(i)
				for f in listedDir:
					ofile = os.path.join( os.path.abspath(i), f )
					absList.append(ofile)
			else:
				ofile = os.path.abspath( i )
				absList.append(ofile)
		
		checkedList = fileTypeChecker( absList )
		
		if oneK == 1:
			sortedProxyDiv = "1k"
		elif webSize == 1:
			sortedProxyDiv = "web"
		else:
			sortedProxyDiv = establishProxyDiv( proxyDivision )
			
		proxyPrep( checkedList, sortedProxyDiv, proxyFolder, openSesame )
			
	else:
		print "\n Error: You must put a file or folder as an input argument.\n"	
	#except:
	#helpSection()
	#return 2
	
def fileTypeChecker( fileList ):
	
	rules = [".jpeg", ".jpg", ".tga", ".tif", ".tiff", ".gif", ".iff", ".png" ]
	checkedList = []
	for i in fileList:
		fileP, extension = os.path.splitext(i)
		if (extension.lower() in rules) and not (i.startswith(".")):
			checkedList.append(i)
		else:
			print "excluding: '" + str(i) + "' -filetype not supported."
	return checkedList

def establishProxyDiv( proxyDivision ):
	##This function is run when no proxy flags are given
	if proxyDivision == 0:
		choiceList = [2,4,8]
		print "\n -->  2.  Makes proxies 1/2 the original resolution dimensions"
		print " -->  3.  Makes proxies 1/3 the original resolution dimensions"
		print " -->  4.  Makes proxies 1/4 the original resolution dimensions"
		print " -->  8.  Makes proxies 1/8 the original resolution dimensions"
		newProxyDivision = input("\n\n Please provide a number choice for divisional level to make proxies: ")
		if not newProxyDivision in choiceList:
			print "\n What you have entered is not in the list of options above, please chose again."
			newProxyDivision = input("\n\n Please provide a number choice for divisional level to make proxies: ")
		
		return int(round(newProxyDivision))
	else:
		return int(round(proxyDivision))

def proxyPrep( fileList, proxyDivision, proxyFolder, openSesame ):
	##This function does some preliminary checking about what the source arguments are and builds the target output folder.
	
	if proxyDivision == "web":
		print "\n proxy target has been set to 640 being the greater res dimension, as a good size for web and email"	
		nameString = "_webProxyRes"
	elif proxyDivision == "1k":
		print "\n proxy target has been set to 1024 being the greater res dimension, as a 1K approximation"
		nameString = "_1kProxyRes"	
	else:	
		print "\n proxyDivisions set to 1/" + str(proxyDivision) + " the resolution of the source files."
		nameString = "_proxyRes"	
		
	filePath, throwaway = os.path.split( fileList[0] )
	targetDest = filePath
	
	if proxyFolder == 1:
		iPath, iFile = os.path.split( filePath )
		newTarg = targetDest + sep + iFile + nameString
		print "\n Target directory: " + newTarg
		if not os.path.exists( newTarg ):
			os.mkdir( newTarg )
		targetDest = newTarg
		makeProxy( fileList, proxyDivision, targetDest, openSesame )
	else:
		for i in fileList:
			print "\n Target directory: " + targetDest
			makeProxy( fileList, proxyDivision, targetDest, openSesame ) 

	return
	
def makeProxy( fileList, proxyDivision, target, openSesame ):
	##This function loops through all the files and creates the actual proxies from the pre-established info.
	
	listLength = str(len(fileList))
	fileNumber = 1
	print "\n making proxies for " + listLength + " files..."
	
	for i in fileList:
		fpath, ffile = os.path.split(i)
		justFileName, extension = os.path.splitext(ffile)
		newProxyname = justFileName.replace("\ ", "_" )
		outfile = target + sep + newProxyname + "_proxy.jpeg"
		if i != outfile: 
		    try: 
		        im = Image.open(i) 
		        origResX, origResY = im.size
		        divValue = getProxyDivision( i, origResX, origResY, proxyDivision )
		        newProxyRes = int(round(origResX/divValue)), int(round(origResY/divValue))
		        newFile = im.resize(newProxyRes, Image.ANTIALIAS)
		        newFile.save(outfile, "JPEG") 
		        print " " + str(fileNumber) + " of " + listLength + " complete."
		        fileNumber = fileNumber + 1
		        
		    except IOError: 
		        print " Proxy creation failed for: ", i
	
	print "\n DONE!\n\n"
	if openSesame == 1:
		try:
			os.popen3("open " + target)	
		except:
			pass
		        
	return

def getProxyDivision( file, resX, resY, proxyDivision ):
	##This function figures the math you need for each picture to get it to your target size.
	
	if type(proxyDivision) != str:
		return proxyDivision
	
	elif proxyDivision == "1k":
		targetRes = 1024
		
	elif proxyDivision == "web":
		targetRes = 640
		
	if resX >= resY:
		#Image is landscape
		if resX >= targetRes:
			proxyDivision = float(resX) / float(targetRes)
			#print "proxyDivision is: " + str(proxyDivision)
			return proxyDivision 
		else:
			proxyDivision = 1
			return proxyDivision

	else:
		#Image is portrait
		if resY >= targetRes:
			proxyDivision = float(resY) / float(targetRes)
			#print "proxyDivision is: " + str(proxyDivision)
			return proxyDivision
		else:
			proxyDivision = 1
			return proxyDivision
	
def helpSection():
	##This is help section which just prints the relevant help info formatted for shell printing 
	print "\n HELP / INSTRUCTIONS: \n"
	print '''
 FLAGS:
 -p\t Sets the divisional amount to create the new smaller res files. The images will be divided by this number.
 -t\t CURRENTLY NOT IMPLEMENTED: is intended to maintain the file format of the original files -otherwise will default to jpeg.
 -w\t Sets the target proxy Res so that the larger dimension is 640 - which is an ideal size for email and web work. 
 	 If images are smaller than this res they will not be altered.
 -1\t Sets the target proxy Res so that the lerger dimension is 1024 - for a 1k approximation. 
 	 If images are smaller than this res they will not be altered.
	'''
	
if __name__ == "__main__":
    sys.exit( main() )    
    
    