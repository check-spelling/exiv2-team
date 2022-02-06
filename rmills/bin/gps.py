#!/usr/bin/python

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
	Camera time is whateve you set in the camera.
	This program will write/read a file tzinfo with the delta info.
	The program guesses that this will be the offset from UTC time
	for your desktop computer!  If the tzinfo exists, it will be read
	and respected.   You can use the tzinfo file to correct for
	camera inaccuracy, incorrect timezone setting and so.
	
	For example for PDT (Pacific Daylight) -07:00, this will be 3600*7 = 25200 (seconds)
	The Camera clock is 28800 seconds behind ZULU
	If you are to the EAST of ZULU, tzinfo will be negative.
	
--------------------
Revision information: 
	$Id: //depot/bin/gps.py#13 $ 
	$Header: //depot/bin/gps.py#13 $ 
	$Date: 2008/06/05 $ 
	$DateTime: 2008/06/05 00:19:23 $ 
	$Change: 146 $ 
	$File: //depot/bin/gps.py $ 
	$Revision: #13 $ 
	$Author: rmills $
--------------------
"""

__author__	= "Robin Mills <robin@clanmills.com>"
__date__	= "$Date: 2008/06/05 $"
__version__	= "$Id: //depot/bin/gps.py#13 $"
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
import surd
import pyexiv2
from   time import altzone,daylight,timezone
import time
import datetime
import xml.dom.minidom
import re

XMLtime     = '%Y-%m-%dT%H:%M:%SZ' #
timediffMax = 180                  # 3 minutes

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



#	# This one definitely should, at least for what I want.
#	object_el2 = mydom.getElementsByTagNameNS(
#		 'http://www.topografix.com/GPX/1/1',"object",
#	)

## 
# XML functions
def getXMLtimez(phototime,delta):
	"""getXMLtimez - convert a datetime to an XML formatted date"""
	#
	# phototime = timedate.timedate("2008-03-16 08:52:15")
	# delta     = seconds
	# -----------------------
	
	timedelta = datetime.timedelta(0,delta,0)
	newtime = phototime + timedelta 
	return newtime.strftime(XMLtime) ;

def getText(nodelist,):
	"""getText(nodeList) - return the text in nodelist"""
	rc = ""
	for node in nodelist:
		if node.nodeType == node.TEXT_NODE:
			rc = rc + node.data
	return rc

def getNodeValue(node):
	"""getNodeValue(node) - return the value of a node"""
	return getText(node.childNodes)

def handleTRKPT(trkpt,timedict,ns):
	"""handleTRKPT"""
	ele	 = getNodeValue(trkpt.getElementsByTagNameNS(ns,"ele" )[0]) if ns else getNodeValue(trkpt.getElementsByTagName("ele" )[0])
	time = getNodeValue(trkpt.getElementsByTagNameNS(ns,"time")[0]) if ns else getNodeValue(trkpt.getElementsByTagName("time")[0])
	lat	 = trkpt.getAttributeNS(ns,"lat") if ns else trkpt.getAttribute("lat") 
	lon	 = trkpt.getAttributeNS(ns,"lon") if ns else trkpt.getAttribute("lon")
	# Garmin .gpx doesn't use a ns on the lat and lon attributes!  Garmin bug?
	if not lat:
		lat = trkpt.getAttribute("lat") 
	if not lon:
		lon = trkpt.getAttribute("lon") 
	  
	# print "lat, lon = %s %s ele,time = %s %s" % ( lat,lon	 , ele,time )
	timedict[time] = [ ele,lat,lon ]

def handleTRKSEG(trkseg,timedict,ns):
	"""handleTRKSEG"""
	trkpts =	 trkseg.getElementsByTagNameNS(ns,"trkpt") if ns else trkseg.getElementsByTagName("trkpt")
	for trkpt in trkpts:
		handleTRKPT(trkpt,timedict,ns)

def handleTRK(trk,timedict,ns):
	"""handleTRK"""
	trksegs = trk.getElementsByTagNameNS(ns,"trkseg") if ns else trk.getElementsByTagName("trkseg")
	for trkseg in trksegs:
		handleTRKSEG(trkseg,timedict,ns)

def handleGPX(gpx,timedict,ns):
	"""handleGPSX"""
	trks =	  gpx.getElementsByTagNameNS(ns,"trk") if ns else gpx.getElementsByTagName("trk")
	for trk in trks:
		handleTRK(trk,timedict,ns)
# 
##

##
# read the tzinfo file to get the time offset (or use the clock)
def getDelta(filedict):
	tzinfo = 'tzinfo'
	delta = altzone if daylight == 1 else timezone

	read = False
	try:
		f = open(tzinfo,'r')
		delta = int(f.readline())
		f.close()
		read = True
	except:
		read= False
	if not read:
		try:
			f = open(tzinfo,'w')
			f.writelines(str(delta))
			f.close()
			read = True
		except:
			read = False
			
	if read:
		tzinfo = os.path.abspath(tzinfo)
		filedict[tzinfo] = tzinfo
			
	
	hours = float(delta) / 3600.0 
	print "delta from tz to UTC = %d:%d:%d hrs" % (d(hours),m(hours),s(hours))
	return delta
#
##

##
# get difference in seconds between two XML time stamps
def tdiff(ts1,ts2):
	return abs( time.mktime(time.strptime(re.sub('\.[0-9]*','',ts1),XMLtime)) \
	          - time.mktime(time.strptime(re.sub('\.[0-9]*','',ts1),XMLtime)) \
	          )

## 
# the program
def gps():
	""" gps - main entry point for program """
	
	ns = 'http://www.topografix.com/GPX/1/1'
	
	filedict = {} # contains file which we find useful (*.gpx and tzinfo)
	delta = getDelta(filedict)
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

		# read the XML with and without the namespace
		handleGPX(dom,timedict,False)
		handleGPX(dom,timedict,ns)
			
		path = os.path.abspath(path)
		filedict[path] = path ;

	print "number of timepoints = ",len(timedict)

	##
	# fild all the images in this this directory
	if len(timedict):
		image 		= 0
		firstTime 	= True
		timetag  = 'Exif.Photo.DateTimeOriginal'
		imagedict = {}
		for path in glob.glob("*"):
			path = os.path.abspath(path)
			if os.path.isfile(path) and not filedict.has_key(path):
				try:
					image     = pyexiv2.ImageMetadata(path)
					image.read()
					timestamp = image[timetag].value
					xmlDate   = getXMLtimez(timestamp,delta)
					imagedict[xmlDate] = path
				except:
					print "*** unable to work with ",path , " ***"
		
		for xmlDate in sorted(imagedict.keys()):
			path = imagedict[xmlDate] ;
			if 1: #try
				image	    = pyexiv2.ImageMetadata(path)
				image.read()
				stamp	    = str(getXMLtimez(image[timetag].value,delta))

				timestamp	= search(timedict,stamp)
				timediff    = tdiff(timestamp,stamp)
				# print "stamp, timestamp = " + stamp + " " + timestamp + " timediff = " + str(timediff)
				if timediff < timediffMax: 
					data		= timedict[timestamp]
	#				print data
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
					sele = "%6.1f" % (ele)
					if ele	< 0:
						ele = -ele
						eleR= 1
					if firstTime:
						print "camera time          nearest gps          latitude   longitude     elev photofile"
						firstTime = False
					slat = "%02d.%02d'" '%02d"%s' % (d(lat),m(lat),s(lat),latR )
					slon = "%02d.%02d'" '%02d"%s' % (d(lon),m(lon),s(lon),lonR )
					print  "%s %s %s %s %s %s" % ( stamp,timestamp,slat,slon,sele,path )
					
					# get Rational number for ele
					# don't why R(ele) is causing trouble!
					# it might be that the denominator is overflowing 32 bits!
					# and this would also import lat and lon
					rele = pyexiv2.utils.Fraction(int(ele*10.0),10)
		
					image['Exif.GPSInfo.GPSAltitude'			] = rele
					image['Exif.GPSInfo.GPSAltitudeRef'			] = str(eleR)
					image['Exif.GPSInfo.GPSDateStamp'			] = stamp
					image['Exif.GPSInfo.GPSLatitude'			] = [R(d(lat)),R(m(lat)),R(s(lat))]
					image['Exif.GPSInfo.GPSLatitudeRef'			] = str(latR)
					image['Exif.GPSInfo.GPSLongitude'			] = [R(d(lon)),R(m(lon)),R(s(lon))]
					image['Exif.GPSInfo.GPSLongitudeRef'		] = str(lonR)
					image['Exif.GPSInfo.GPSMapDatum'			] = 'WGS-84'
					image['Exif.GPSInfo.GPSProcessingMethod'	] = '65 83 67 73 73 0 0 0 72 89 66 82 73 68 45 70 73 88 ' 
					image['Exif.GPSInfo.GPSTimeStamp'			] = [R(10),R(20),R(30)]
					image['Exif.GPSInfo.GPSVersionID'			] = '2 2 0 0'
					image.write()
				else:
					print "ignoring " + path + " ** not in timedict ** timediff = " + str(timediff) + " seconds"
			#except:
			#	print "*** problem with ",path , " ***"
		
		image = 0

	# That's all folks!
	##
#
##

if __name__ == '__main__':
	gps()
