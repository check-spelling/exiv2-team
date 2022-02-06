#!/usr/bin/env python

r"""gps - a program to update the exif data in images using GPX files

This requires:
	surd.py - surd support (rational numbers)
	pyexiv2.py - libexiv2 support (for reading/writing EXIF data)
	
To use this:
	run gps.py in a directory of .jpg and .gpx files
	
	the program reads all the gpx files to construct a time dictionary
	then it reads all the photos and updates the GPS/EXIF data to give
	the photo the closest location in the time dictionary
	
	The program has to guess the difference between GPS time and camera time.
	GPS time is UTC (GMT) time.
	Camera time is whatever you set in the camera.
	This program will write/read a file tzinfo with the delta info.
	The program guesses that this will be the offset from UTC time
	for your desktop computer!  If the tzinfo exists, it will be read
	and respected.   You can use the tzinfo file to correct for
	camera inaccuracy, incorrect timezone setting and so.
	
	For example for PSD (Pacific Daylight) -07:00, this will be 3600*7 = 25200 (seconds)
	The Camera clock is 28800 seconds behind ZULU
	If you are to the EAST of ZULU, tzinfo will be negative.
	
--------------------
Revision information: 
	$Id: //depot/bin/gps.py#10 $ 
	$Header: //depot/bin/gps.py#10 $ 
	$Date: 2008/04/14 $ 
	$DateTime: 2008/04/14 22:07:18 $ 
	$Change: 102 $ 
	$File: //depot/bin/gps.py $ 
	$Revision: #10 $ 
	$Author: rmills $
--------------------
"""

__author__	= "Robin Mills <robin@clanmills.com>"
__date__	= "$Date: 2008/04/14 $"
__version__	= "$Id: //depot/bin/gps.py#10 $"
__credits__	= """Everybody who contributed to Python.

Especially: Guido van Rossum for creating the language.
And: Mark Lutz for the O'Reilly Books to explain it.
And: Ka-Ping Yee for the wonderful module 'pydoc'.

Olivier Tilloy for the pyexiv2 python wrapper code
Andreas Huggel for the libexiv2 library
"""

import sys
import os
import glob
import time
import datetime
import xml.dom.minidom
import math

## 
# XML functions
def getText(nodelist):
	"""getText(nodeList) - return the text in nodelist"""
	rc = ""
	for node in nodelist:
		if node.nodeType == node.TEXT_NODE:
			rc = rc + node.data
	return rc

def getNodeValue(node):
	"""getNodeValue(node) - return the value of a node"""
	return getText(node.childNodes)

def handleTRKPT(trkpt,timedict):
	"""handleTRKPT"""
	ele	 = getNodeValue(trkpt.getElementsByTagName("ele")[0])
	time = getNodeValue(trkpt.getElementsByTagName("time")[0])
	lat	 = trkpt.getAttribute("lat")
	lon	 = trkpt.getAttribute("lon")
	# print "lat, lon = %s %s ele,time = %s %s" % ( lat,lon	 , ele,time )
	timedict[time] = [ ele,lat,lon ]

def handleTRKSEG(trkseg,timedict):
	"""handleTRKSEG"""
	trkpts =	 trkseg.getElementsByTagName("trkpt")
	for trkpt in trkpts:
		handleTRKPT(trkpt,timedict)

def handleTRK(trk,timedict):
	"""handleTRK"""
	trksegs = trk.getElementsByTagName("trkseg")
	for trkseg in trksegs:
		handleTRKSEG(trkseg,timedict)

def handleGPX(gpx,timedict):
	"""handleGPSX"""
	trks =	  gpx.getElementsByTagName("trk")
	for trk in trks:
		handleTRK(trk,timedict)
# 
##

## 
# the program
def gps():
	""" gps - main entry point for program """
	
	filedict = {} # contains file which we find useful (*.gpx and tzinfo)
	##
	# build the timedict from the gpx files in this directory
	# 
	timedict = {}
	for path in glob.glob("*.gpx"):
		file	 = open(path,"r")
		data	 = file.read(os.path.getsize(path))
		print "reading ",path
		file.close()
		dom = xml.dom.minidom.parseString(data)

		handleGPX(dom,timedict)
		
		path = os.path.abspath(path)
		filedict[path] = path ;

	print "number of timepoints = ",len(timedict)
	
	running = False
	point   = 0
	
	##
	# run over the jpg files in this directory
	if len(timedict):
		for xmlDate in sorted(timedict.keys()):
			point += 1
			[ ele,lat,lon ] = timedict[xmlDate]
			ele = float(ele)
			lat = float(lat)
			lon = float(lon)
			if running:
				dist = math.sqrt( (lat1-lat)*(lat1-lat) + (lon1-lon)*(lon1-lon))
				if dist > 0.002 or point == len(timedict):
					print "dist",dist, " point = ",point
					running = False
			if not running:
				ele1 = ele 
				lat1 = lat
				lon1 = lon
				running = True

	# That's all folks!
	##
#
##

if __name__ == '__main__':
	gps()
