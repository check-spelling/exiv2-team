#!/usr/bin/env python

r"""gps - a program to update the exif data in a photographs from GPX files

This requires:
	surd.py - surd support (rational numbers)
	pyexiv2.py - libexiv2 support (for reading/writing EXIF data)
	
To use this:
	simply run gps.py in a directory of .jpg and .gpx files
	the program reads all the gpx files to construct a time dictionary
	then it reads all the photos and updates the GPS/EXIF data to give
	the photo the closest location in the time dictionary
	
--------------------
Revision information: 
	$Id: //depot/bin/gps.py#9 $ 
	$Header: //depot/bin/gps.py#9 $ 
	$Date: 2008/04/04 $ 
	$DateTime: 2008/04/04 21:56:58 $ 
	$Change: 96 $ 
	$File: //depot/bin/gps.py $ 
	$Revision: #9 $ 
	$Author: rmills $
--------------------
"""

__author__	= "Robin Mills <robin@clanmills.com>"
__date__	= "$Date: 2008/04/04 $"
__version__	= "$Id: //depot/bin/gps.py#9 $"
__credits__	= """Everybody who contributed to Python.
Especially: Guido van Rossum for creating the language.
And: Mark Lutz for the O'Reilly Books to explain it.
And: Ka-Ping Yee for the wonderful module 'pydoc'.
"""

import sys
import os
import glob
import surd
import pyexiv2
from time import altzone,daylight,timezone
import time
import datetime
import xml.dom.minidom
import re

##
# Ration number support
def R(f):
	"""R(float) - get a Rational number for a float"""
	s = surd.surd(float(f))
	return pyexiv2.Rational(s.num,s.denom) 
	
def d(angle):
	"""d(any) - get degrees from a number :eg d(33.41) -> 33"""
	return int(angle)
	
def m(angle):
	"""m(any) - get minutes from a number :eg d(33.41) -> 24"""
	return int( angle*60 - d(angle)* 60)

def s(angle):
	"""s(any) - get seconds from a number :eg s(33.41) -> 36"""
	return int( angle*3600 - d(angle)*3600 - m(angle)*60 )

#
##


##
# dictionary search (closest match)
def search(dict,target):
	"""search(dict,target) - search for closest match"""
	s	 = sorted(dict.keys())
	N	 = len(s)
	low	 = 0
	high = N-1
	
	while low < high:
		mid = (low + high)/2
		if s[mid] < target:
			low = mid + 1
		else:
			high = mid
	return s[low]		
#
##

## 
# XML functions
def getXMLtimez(phototime):
	"""getXMLtimz - convert a datetime to an XML formatted date"""
	#
	# phototime = "2008-03-16 08:52:15"
	# -----------------------
	# get the  timezone and time offset the Zulu time
	
	# delta = gps.delta # time.altzone if time.daylight == 1 else time.timezone
	#- name = time.tzname[time.daylight]

	# print delta, "secs = ",delta/60,"mins = ",delta/3600,"hrs tzone = ",name
	# delta = 3600 * 7
	delta = altzone if daylight == 1 else timezone
	timedelta = datetime.timedelta(0,delta,0)
	# print timedelta #	 , " => " , timedelta.__class__

	# -----------------------
	# parse a date string
	# photo	   = str(phototime) # "2008-03-16 08:52:15"
	# phototime	 = datetime.datetime.strptime(photo,'%Y-%m-%d %H:%M:%S')

	newtime = phototime + timedelta 
	# print newtime #, " => ",newtime.__class__

	return newtime.strftime('%Y-%m-%dT%H:%M:%SZ') ;

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

	print "number of timepoints = ",len(timedict)

	##
	# run over the jpg files in this directory
	if len(timedict):
		image 		= 0
		firstTime 	= True
		pathdict = {}
		for path in glob.glob("*"):
			try:
				image = pyexiv2.Image(path)
				image.readMetadata()
				timestamp = image['Exif.Image.DateTime']
				xmlDate = getXMLtimez(timestamp)
				pathdict[xmlDate] = path
			except:
				print "*** unable to work with ",path , " ***"
		
		for xmlDate in sorted(pathdict.keys()):
			path = pathdict[xmlDate] ;
			try:
				image		= pyexiv2.Image(path)
				image.readMetadata()
				stamp		= str(getXMLtimez(image['Exif.Image.DateTime']))

				timestamp	= search(timedict,stamp) 
				data		= timedict[timestamp]
				ele			= float(data[0])
				lat			= float(data[1])
				lon			= float(data[2])
		
				latR	= 'N'
				lonR	= 'E'
				eleR	=  0
				if lat	< 0:
					lat = -lat
					latR= 'S'
				if lon	< 0:
					lon = -lon
					lonR= 'W'
				if ele	< 0:
					ele = -ele
					eleR= 1
				if firstTime:
					print "camera time          nearest gps          latitude   longitude     elev photofile"
					firstTime = False
				slat = "%02d.%02d'" '%02d"%s' % (d(lat),m(lat),s(lat),latR )
				slon = "%02d.%02d'" '%02d"%s' % (d(lon),m(lon),s(lon),lonR )
				sele = "%6.1f" % (ele)
				print  "%s %s %s %s %s %s" % ( stamp,timestamp,slat,slon,sele,path )
				
				raw_input('just a second > ')
				
				# get Rational number for ele
				# don't why R(ele) is causing trouble!
				# it might be that the denominator is overflowing 32 bits!
				# and this would also import lat and lon
				rele = pyexiv2.Rational(int(ele*10.0),10)
	
				image['Exif.GPSInfo.GPSAltitude'			] = rele
				image['Exif.GPSInfo.GPSAltitudeRef'			] = eleR
				image['Exif.GPSInfo.GPSDateStamp'			] = stamp
				image['Exif.GPSInfo.GPSLatitude'			] = [R(d(lat)),R(m(lat)),R(s(lat))]
				image['Exif.GPSInfo.GPSLatitudeRef'			] = latR
				image['Exif.GPSInfo.GPSLongitude'			] = [R(d(lon)),R(m(lon)),R(s(lon))]
				image['Exif.GPSInfo.GPSLongitudeRef'		] = lonR
				image['Exif.GPSInfo.GPSMapDatum'			] = 'WGS-84'
				image['Exif.GPSInfo.GPSProcessingMethod'	] = '65 83 67 73 73 0 0 0 72 89 66 82 73 68 45 70 73 88 ' 
				image['Exif.GPSInfo.GPSTimeStamp'			] = [R(10),R(20),R(30)]
				image['Exif.GPSInfo.GPSVersionID'			] = '2 2 0 0'
				image.writeMetadata()
			except:
				print "*** problem with ",path , " ***"
		
		image = 0

	# That's all folks!
	##
#
##

if __name__ == '__main__':
	gps()
