#include "Platform.h"

#include "Utility.h"

#ifdef WIN32
// Windows

#include <direct.h> // _mkdir
#include <io.h> // _access

#undef access
#define access _access

bool makedir( const char * cszPath )
{
	return ( _mkdir( cszPath ) == 0 );
}

#else
// Linux

// getch/getche
#include <termios.h>
#include <stdio.h>

// mkdir
#include <sys/types.h>
#include <sys/stat.h>

//----------------------------------------------------------------------------
//getch/getche

static struct termios old, cur;

// Initialize new terminal i/o settings
void initTermios( int echo ) 
{
	tcgetattr( 0, &old );				// grab old terminal i/o settings
	cur = old;							// make new settings same as old settings
	cur.c_lflag &= ~ICANON;				// disable buffered i/o
	cur.c_lflag &= echo ? ECHO : ~ECHO;	// set echo mode
	tcsetattr( 0, TCSANOW, &cur );		// use these new terminal i/o settings now
}

// Restore old terminal i/o settings
void resetTermios( void ) 
{
	tcsetattr( 0, TCSANOW, &old );
}

// Read 1 character - echo defines echo mode
char getch_( int echo )
{
	initTermios( echo );
	char ch = getchar();
	resetTermios();
	return ch;
}

char getch( void )
{
	return getch_( 0 );
}

char getche( void )
{
	return getch_( 1 );
}

//----------------------------------------------------------------------------
// mkdir

bool makedir( const char * cszPath )
{
	return ( mkdir( sPath.c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH ) == 0 );
}

#endif

bool direxists( const char * dir )
{
	if ( !IS_CSTR_VALID( dir ) )
		return false;

	if ( access( dir, 0 ) != 0 )
		return false;
	
	struct stat status;
	stat( dir, &status );
	
	return ( status.st_mode & S_IFDIR );
}

bool fileexists( const char * file )
{
	if ( !IS_CSTR_VALID( file ) )
		return false;

	if( access( file, 0 ) != 0 )
		return false;

	struct stat status;
	stat( file, &status );

	return !( status.st_mode & S_IFDIR );
}
