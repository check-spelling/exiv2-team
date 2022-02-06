/* STAT.C: This program uses the _stat function to
 * report information about the file named STAT.C.
 */

#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

const char* leafname(const char* filename)
{
    const char* leaf = filename ;
    bool        delim[256] ;
    for ( int i = 0 ; i < sizeof delim/sizeof delim[0] ; i++ ) delim[i] = false ;
    delim['\\'] = true ;
    delim[':' ] = true ;
    delim['/' ] = true ;
    if ( filename ) {
      leaf += strlen(filename) -1 ;
      // step up before the "/" delimiter
      while ( leaf > filename && !delim[leaf[0]] ) leaf -- ;
      if (    delim[leaf[0]]                     ) leaf ++ ;
    }
      
    return leaf ;
}

int main( int argc, const char* argv[] )
{
	if ( argc != 2 ) {
		printf("syntax: %s filename\n",argv[0]) ;
		return 0 ;
	}
	
	struct stat buf      ;

	/* Get data associated with "stat.cpp": */
	const char* filename = argc > 1 ? argv[1] : "stat.cpp" ;
	int         result   = stat( filename, &buf );

   	/* Check if statistics are valid: */
   	if ( result != 0 )
   	{
      	printf( "Problem getting information from file %s\n",filename );
   	}
   	else
   	{
      	/* Output some of the statistics: */
      	printf( "Filename      : %s\n",filename) ;
      	printf( "Leaf          : %s\n",leafname(filename)) ;
      	printf( "File size     : %ud\n", (unsigned int)buf.st_size );
      	printf( "Drive         : %c:\n", buf.st_dev + 'A' );
      	printf( "Time modified : %s", ctime( &buf.st_mtime ) );
	  	printf( "Age           : %ud seconds\n",(unsigned int)(time(NULL) - buf.st_mtime)) ;
	  

	 	// what's the current date?
   		time_t      ltime ;
   		time      (&ltime);
  		struct tm*  today = localtime( &ltime );

   		char      sShortDate[100] ;
  		char      sLongDate[100]  ;
      	strftime( sShortDate, sizeof sShortDate,"%c" ,today );
      	strftime( sLongDate , sizeof sLongDate ,"%+"/*"%#c"*/,today );

      	printf("\n") ;
      	printf("Current ShortDate = %s\n",sShortDate) ;
      	printf("Current LongDate  = %s\n",sLongDate) ;


      	struct tm*  ftime = localtime( &buf.st_mtime );
      	strftime( sShortDate, sizeof sShortDate,"%c" ,ftime );
      	strftime( sLongDate , sizeof sLongDate ,"%+"/*"%#c"*/,ftime );

      	printf("\n") ;
      	printf("File    ShortDate = %s\n",sShortDate) ;
      	printf("File    LongDate  = %s\n",sLongDate) ;
	}

   	return 0 ;
}
