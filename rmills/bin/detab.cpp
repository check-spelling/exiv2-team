/*	(c) Copyright Robin Mills Software Consultancy 2007-
	San Jose, CA USA.                All rights reserved
	http://www.clanmills.com         robin@clanmills.com
-----------------------------------------------------------------
* File   : detab.cpp
* Author : Robin Mills
* Date   : 20071018      (ccyymmdd)
-----------------------------------------------------------------

* Purpose:
  Detab code and format code for the web

123456789012345678901234567890
	1
		2
			3
				4
    1   2   3   4

* Usage :
  detab filename

* Example:
  None

* Description:
  None

* Restrictions:
  None

* Ideas to extend this:
  None

* More information:
  None

* Revision history at bottom of file

-----------------------------------------------------------------
*/

#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

#ifdef  _MSC_VER
#define strcasecmp _stricmp
static char buff[512];
char* dirnamename(char* x)
{
	strcpy(buff,x);
	*strchr(buff,'\\')=0;
	return buff;
}
char* basename(char* x)
{
	strcpy(buff,x);
	return strstr(buff,"\\");
}
#else
#include <libgen.h>
#include <sys/param.h>
#endif

#define        MAXLINE        1024*8           // maximum line length

// what are we doing?
typedef enum
{	kNopreformat = 0
,   kPreformat = 1
,   kUnpreformat = 2
} preformat_e  ;

static preformat_e preformat = kNopreformat ;

int getline(FILE* file,char s[], int lim)
{
	int c, i;
	for (i = 0 ; ((c=fgetc(file)) != EOF) ; ++i) {
		if ( i < MAXLINE-3 ) {
			s[i] = c;
			s[i+1] = 0 ;
		}
		if ( c == '\n' ) break ;
	}

//	printf("getline %d %s\n",i,s) ;

	int result = (c == EOF && i==0) ? EOF : i+1 ;
	s[result == EOF ? 0 : result] = 0 ;
	return result ;
}

void printHeader(const char* filename)
{
	if ( !preformat ) {
		printf(
		"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">"
		"<html>\n"
		"<head><title>%s</title>\n"
		"</head>\n"
		"<body>\n"
		"<link rel=\"stylesheet\" type=\"text/css\" href=\"/page.css\">\n"
		"<!--#include virtual=\"/menu.inc\" -->\n"
		"<div id = \"Content\" style=\"width:800px\">\n"
		"<h1>%s         <a href=\"./\"><img src=\"/up.gif\"  border=1></a></h1>\n"
		"<pre>\n"
		, filename, filename
		) ;
	}  else if ( preformat == kPreformat ) {
		printf("<pre>") ;
	}
}

void printFooter()
{
	if ( !preformat ) {
		printf("</pre>\n") ;
		printf("</html>\n") ;
	} else if ( preformat == kPreformat ) {
		printf("</pre>\n") ;
	}
}

int syntax()
{
	fprintf(stderr,"usage detab [-preformat] [[-web] [-linenumbers] [-tab n] [filename]]+\n") ;
	return -1 ;
}

void compress(int* pi,int* pargc,char* argv[])
{
	int i 		= *pi ;
	int argc 	= *pargc ;

	for ( int j = i+1 ; j < argc ; j++ ) {
	 	argv[j-1] = argv[j] ;
	}

	*pi 	= --i 	 ;
	*pargc = --argc ;

//	printf("argv: ") ;	for ( i = 0 ; i < argc ; i++ ) printf("%s ",argv[i]) ;	printf("\n") ;
}

preformat_e sniff(char* line)
{
	return strncmp(line,"<pre>",5) ? kPreformat : kUnpreformat ;
}

void unpreformat(char* line)
{
	if (  preformat != kUnpreformat ) return ;

	char* x ;
	while ( (x = strstr(line,"&lt;")) ) {
		*x = '<' ;
		strcpy(x+1,x+5) ;
	}
	while ( (x = strstr(line,"&gt;")) ) {
		*x = '>' ;
		strcpy(x+1,x+5) ;
	}
	while ( (x = strstr(line,"<pre>")) ) {
		strcpy(x,x+5) ;
	}
	while ( (x = strstr(line,"</pre>")) ) {
		strcpy(x,x+6) ;
	}
}

int main(int argc,char* argv[])
{
	char	line[MAXLINE]		;

	bool    bWeb 		= false ;
	bool    bLineNumber = false ;

	int     i 					;
	int     tab		= 4			;
	int 	nErr	= 0			;

	// look for options
	for ( i = 1 ; i < argc ; i++ ) {
		if ( strcasecmp(argv[i],"-web") == 0 ) {
			bWeb = true ;
			compress(&i,&argc,argv) ;
		}
		else if ( strcasecmp(argv[i],"-linenumbers") == 0 ) {
			bLineNumber = true ;
			compress(&i,&argc,argv) ;
		}
		else if ( strcasecmp(argv[i],"-preformat") == 0 ) {
			preformat = kPreformat ;
			bWeb   = true ;
			compress(&i,&argc,argv) ;
		}
		else if ( strcasecmp(argv[i],"-tab") == 0 && (i < (argc-1)) ) {
			tab = atoi(argv[++i]) ;
			if ( tab < 0 || tab > 100 ) tab = 4 ;
			compress(&i,&argc,argv) ;
			compress(&i,&argc,argv) ;
		} else {
			const char*	filename= argv[i] ;
			bool bIn  = filename[0] == '-' && filename[1] == 0 ;
			if (!bIn) {
				FILE*   file = fopen(filename,"r") ;
				if ( !file ) {
					fprintf(stderr,"unable to open file %s\n",filename) ;
					nErr++ ;
				}
				fclose(file) ;
			}
		}
	}

	// check there's work to do
	if ( argc < 2 || nErr ) return syntax() ;

	// do the business
	for ( i = 1 ; i < argc ; i++ ) {
		char*		filename = argv[i] ;
		bool bIn  = filename[0] == '-' && filename[1] == 0 ;
		FILE*   	file 	 = bIn ? stdin : fopen(filename,"r") ;
		int         nLine    = 0 ;

		while ( getline(file,line, MAXLINE) != EOF )
		{
			if ( !nLine && preformat ) {
				preformat = sniff(line) ;
				if ( preformat == kUnpreformat ) {
					bWeb = false ;
				}
				printHeader(basename(filename)) ;
			}
			unpreformat(line) ;
			nLine++ ;

			if ( bLineNumber ) printf("%5d: ",nLine) ;
			int k = 0 ;
			if ( line[0] ) for ( int i = 0 ; line[i] ; i++)
			{
				int c = line[i] ;
				switch ( c ) {
					case '\t' 	:
					{
						int n      = k % tab     ;
						int spaces = tab     - n ;
						for ( int j = 0; j < spaces ; ++j)
						{
							putchar(' ');
							k++ ;
						}
						k-- ; // back up, because we always add 1 later!
					}
					break ;

					case '<' 	: if ( bWeb ) printf("%s","&lt;") ; else putchar(c) ; break ;
					case '>' 	: if ( bWeb ) printf("%s","&gt;") ; else putchar(c) ; break ;


					case '\n'   : line[i+1] = 0 ; // drop thru
					default		: putchar(c);
					break ;
				}
				k++;
			}
		}
		printFooter() ;
	}


	return 0;

}

