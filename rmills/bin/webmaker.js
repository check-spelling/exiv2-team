#!/usr/local/bin/js

main(arguments) ;

function main(arguments)
{

if ( ! arguments.length ) return print("useage: webmaker <photo-directory> title webdirectory url nCols\n") ;

// Options
var directory 	= arguments.length > 0 ? new File(arguments[0].toString()) 	: null								;
var title 		= arguments.length > 1 ? arguments[1].toString() 			: "Title of Web Site"				;
var dir   		= arguments.length > 2 ? arguments[2].toString() 			: "/Users/rmills/clanmills/test/"	;
var url			= arguments.length > 3 ? arguments[3].toString()            : "http://clanmills/test"           ;
var nCols		= arguments.length > 4 ? arguments[4].toString() 			: 3									;
var extension   = '.shtml' ;

var pageTitle   = title ;

if ( ! directory ) return print("unable to open photodirectory\n") ;

nCols = Number(nCols) ;
if ( nCols < 1 || nCols > 10 ) nCols = 3 ;

if ( dir[dir.length-1] != '/' ) dir += "/" ;
print("input: title = " + title) ;
print("input: dir   = " + dir  ) ;
print("input: nCols = " + nCols) ;

if ( !createDir(dir)          ) return ;
if ( !createDir(dir+"Images/")) return ;
if ( !createDir(dir+"Thumbs/")) return ;


function createDir(dir)
{
	var e ;
	var top = new File("/") ;
	try {
		top.mkdir(dir) ;
	} catch ( e ) {} ;
	
	var d = new File(dir) ;
	var r = d && d.isDirectory ;
	if ( !r ) {
		print("unable to find/create directory " + dir) ;
	}
	return r ;
}

function sortlastModified(a, b)
{
	return ( a.lastModified.valueOf() - b.lastModified.valueOf() ) > 0 ? 1 : -1 ;
	
//	var x = a.lastModified.valueOf() - b.lastModified.valueOf() ;
//	var r 	= x > 0 ? 1
//			: x == 0 ? 0 
//			: -1
//			;
//	print('compare a.name and b.name result = ' + a.name + ',' + b.name + ' = ' + r) ;
//	return r ;
}

function fileOpenForWrite(path)
{
	print(path) ;
	var file = new File( path ) ;
	if ( file && file.exists ) file.remove() ;
	file.open('write,text,create') ;
	return file ;
}

function writeShortFooter(file)
{
	file.writeln("</div>") ;
	file.writeln("</body>") ;
	file.writeln("</html>") ;
}

function writeFooter(file,dateTitle,date)
{
	file.writeln("<hr>") ;
	file.writeln("<center>") ;
	file.writeln("  <p align=\"middle\">") ;
	file.writeln("    <img src=\"/robinali.gif\" align=\"right\" width=120><br>") ;
	file.writeln("    <a href=\"/\">Home</a> <a>.........</a> <a href=\"/about" + extension +"\">About</a>") ;
	file.writeln("  <br><br>") ;
	file.writeln("  Page design &copy; 1996-2008 Robin Mills / <a href=\"mailto:webmaster@clanmills.com\">webmaster@clanmills.com</a><br><br>") ;
	file.writeln(dateTitle + date.toDateString() + " " + date.toTimeString()) ;
	file.writeln("  </p>") ;
	file.writeln("</center>") ;
	file.writeln("") ;
	writeShortFooter(file) ;
}

function writeHeader(file,title)
{
	file.writeln("<html>") ;
	file.writeln("") ;
	file.writeln("<head>") ;
	file.writeln("<link rel=\"stylesheet\" type=\"text/css\" href=\"/album.css\"></link>") ;
	file.writeln("<title>" + title + "</title>") ;
	file.writeln("</head>") ;
	file.writeln("") ;
	file.writeln("<body>") ;
	file.writeln("<!--#include virtual=\"/menu.inc\" -->") ;
	file.writeln("<div id = \"Content\">") ;
	file.writeln("") ;
}

function cutPlaces(n,p)
{
	s = n.toString()          ;
	l = s.indexOf('.')        ;
	if ( l < 0 ) l = s.length ;
	return s.substr(0,l+p+1)  ;
}

// ---------------------------------------
// find all the JPG and JPEG files
var  list1 = directory.list(/\.jpg$/i ) ;
var  list2 = directory.list(/\.jpeg$/i) ;
var  list  = new Array() ;
for ( i = 0 ; i < list1.length ; i++ ) list[list.length] = list1[i] ;
for ( i = 0 ; i < list2.length ; i++ ) list[list.length] = list2[i] ;
list1 = null ;
list2 = null ;

// ---------------------------------------
// sort them
list.sort(sortlastModified) ;
// for ( var i = 0 ; i < list.length ; i++ ) print(list[i].name + " -> " + list[i].lastModified + " = " + (list[i].lastModified.valueOf() - 1200976990000)) ;
// return 0 ;

// ---------------------------------------
// get the files, names and exts
var files = new Array() ; // path of the file
var names = new Array() ; // basename without extension
var exts  = new Array() ; // extension

for ( var i = 0 ; i < list.length ; i++ )
{
	files[i] = list[i].toString() ;
	var name = list[i].name       ;
	var ext1 = name.match(/\.jpg$/i ) ;
	var ext2 = name.match(/\.jpeg$/i) ;
	
	if ( ext1 ) exts [i] = ext1.toString()  ;
	if ( ext2 ) exts [i] = ext2.toString()  ;

	names[i] = name.substring(0,name.length - exts[i].length) ;
}

var sizeImage = 0 ;
var sizeThumb = 0 ;

// ---------------------------------------
// create the Thumbnails and Images
for ( var n = 0 ; n < names.length ; n++ ) {
	var iwidth  = 750            ;
	var twidth  = iwidth / nCols ;
	var name 	= names[n] ;
	var ext 	= exts [n] ;
	var input   = ' "' + list[n].toString() + '"' ;
	var image   = ' "' + dir + "Images/" + name + ext + '"' ;
	var thumb   = ' "' + dir + "Thumbs/" + name + ext + '"' ;
	// and set the compression [low|normal|high|best|]
	var icmd = 'sips --setProperty formatOptions normal --resampleHeightWidthMax ' + iwidth + input + ' --out ' + image ;
	var tcmd = 'sips --setProperty formatOptions normal --resampleHeightWidthMax ' + twidth + input + ' --out ' + thumb ;
// 	print (icmd) ;
	system(icmd) ;			
//	print (tcmd) ;
	system(tcmd) ;
	
	image   = dir + "Images/" + name + ext ;
	thumb   = dir + "Thumbs/" + name + ext ;
	sizeImage += File(image).size ;
	sizeThumb += File(thumb).size ;
}

var totalImage = sizeImage ; // + sizeThumb ;
if ( totalImage > 1.8 * 1024 * 1024 ) {
	totalImage = "" + cutPlaces((totalImage / (1024*1024)),2).toString() + "mb" ;
} else {
	totalImage = "" + cutPlaces((totalImage / 1024       ),2).toString() + "kb" ;
}

print("sizeImage,sizeThumb = " + sizeImage + "," + sizeThumb + " => " + totalImage) ;	

// ---------------------------------------
// write out the HTML for every page

for ( var n = 0 ; n < names.length ; n++ ) {
	var l = names.length ;

	var name 	= names[n] ;
	var ext     = exts [n] ;
	var date    = list [n].lastModified ;
	var dateTitle   = "Photo taken: " ;
	
	var pname 	= n == 0 		? "default" : names[n-1] ;
	var nname 	= n == (l-1)	? "default" : names[n+1] ;
	var path    = dir + name + extension ;	
	var default_  = 'default'              ;
	
	var file = fileOpenForWrite(path) ;

	writeHeader(file,name) ;
	file.writeln("<table>") ;
	file.writeln("  <tr>") ;
	file.writeln("    <td align=\"right\"><h1>" + name + "</h1></td>") ;
	file.writeln("  </tr>") ;
	file.writeln("  <tr>") ;
	file.writeln("    <td>") ;
	file.writeln("      <a href=\"" + escape(pname)  + extension + "\"><img src=\"/prev.gif\"></a>") ;
	file.writeln("      <a href=\"" + escape(default_) + extension + "\"><img src=\"/up.gif\"></a>") ;
	file.writeln("      <a href=\"" + escape(nname)  + extension + "\"><img src=\"/next.gif\"></a>") ;
	file.writeln("      &nbsp;" + (n+1) + " of " + l ) ;
	file.writeln("    </td>") ;
	file.writeln("  </tr>") ;
	file.writeln("  <tr><td><img src=\"Images/" + escape(name) + ext + "\" border=2></td></tr>") ;
	file.writeln("</table>") ;
	file.writeln("") ;
	writeFooter(file,dateTitle,date) ;
	
	file.close() ;
}

// ---------------------------------------
// write out the HTML for the index page

	var date    	= new Date() ;
	var dateTitle   = "Page created: "            ;
	var path    	= dir + "default" + extension ;	
	var file 		= fileOpenForWrite(path) ;

	writeHeader(file,pageTitle) ;

	file.writeln("<h1>" + pageTitle + "</h1>") ;
	file.writeln("<table><tr><td colspan=\"" + nCols +"\">") ;
	file.writeln("") ;
	file.writeln("<p>Lightbox <a href=\"lightbox"+extension+"\">click here</a> - " + totalImage + " download</p>") ;
	file.writeln("</td></tr><tr>") ;
	
	for ( var n = 0 ; n < names.length ; n++ ) {
		var name 	= names[n] ;
		var ext 	= exts [n] ;
  		file.writeln("<td valign=bottom><center><a href=\"" + escape(name) + extension+"\"><img src=\"Thumbs/" + escape(name) + ext + "\"</a><br>" + name + "</center></td>") ;
  	
  		var bTableEnd	= ( n == (names.length-1)) ;
  		var bRowEnd 	= (n % nCols) == (nCols-1) ;
  	
  		if ( bRowEnd && !bTableEnd ) file.writeln( "</tr>") ;
	}

	file.writeln("</tr></table>") ;
	
	writeFooter(file,dateTitle,date) ;
	file.close() ;


// ---------------------------------------
// write out the HTML for the lightbox page

	var date    	= new Date() 				;
	var dateTitle   = "Page created: "	 		;
	var path    	= dir + "lightbox" + extension ;	
	var file 		= fileOpenForWrite(path)	;
	
	writeHeader(file,pageTitle) ;
	file.writeln("<script type=\"text/javascript\" src=\"/js/lightbox.js\"></script>") ;	

	file.writeln("<h1>" + title + "</h1>") ;
	
	file.writeln("<input type=\"button\"  name=\"run\"     value=\"Run\"     tabindex=\"1\"   onClick=\"Run()\"/>") ;
	file.writeln("<input type=\"button\"  name=\"stop\"    value=\"Stop\"    tabindex=\"2\"   onClick=\"Stop()\"/>") ;
	file.writeln("<input type=\"button\"  name=\"grid\"    value=\"Grid\"    tabindex=\"3\"   onClick=\"Arrange(3,280,290, 0, 0)\"/>") ;
	file.writeln("<input type=\"button\"  name=\"fridge\"  value=\"Fridge\"  tabindex=\"4\"   onClick=\"Arrange(5,180,200,30,30)\"/>") ;
	file.writeln("<input type=\"button\"  name=\"wide\"    value=\"Wide\"    tabindex=\"5\"   onClick=\"Arrange(8,150,180,40,40)\"/>") ;
	file.writeln("<input type=\"button\"  name=\"random\"  value=\"Random\"  tabindex=\"6\"   onClick=\"Arrange(1,0,0,800,500)\"/>") ;
	file.writeln("<input type=\"button\"  name=\"contact\" value=\"Contact\" tabindex=\"7\"   onClick=\"location='default"+extension+"';\"/>") ;
	file.writeln("<input type=\"button\"  name=\"small\"   value=\"Small\"   tabindex=\"8\"   onClick=\"Small()\"/>") ;
	file.writeln("<input type=\"button\"  name=\"large\"   value=\"Large\"   tabindex=\"9\"   onClick=\"Large()\"/>") ;
	file.writeln("<div style=\"left:200px;top:80px;position:absolute;\">") ;
	file.writeln("<script language=\"JavaScript\" TYPE=\"text/javascript\">") ;
	file.writeln("<!--") ;
	file.writeln("photos = [") ;
	for ( var n = 0 ; n < names.length ; n++ ) {
		var name 	= names[n] ;
		var ext 	= exts [n] ;
		var sEnd    = n != names.length -1 ? "," : "];" ;
		file.writeln("'Thumbs/" + escape(name) + escape(ext) + "'" + sEnd ) ;
	}
	
    file.writeln("theDoc(5,180,200,30,30) ;") ;
    file.writeln("var   images = new Array() ;") ;
    file.writeln("for ( i = 0 ; i < photos.length ; i++ ) {") ;
    file.writeln("  var p = photos[i] ;") ;
    file.writeln("  p = p.replace(\"Thumbs/\",\"Images/\") ;") ;
    file.writeln("  images[i] = new Image() ;") ;
    file.writeln("  images[i].src = p ;") ;
    file.writeln("  window.status = \"loading \" + p ;") ;
    file.writeln("}") ;
    file.writeln("window.status = \"done loading images\" ;") ;
	file.writeln("//-->") ;
	file.writeln("</script>") ;
		
	writeShortFooter(file) ;
	file.close() ;

	system('open ' + url) ;
	
}
