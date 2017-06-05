#include "Platform.h"

#ifdef WIN32
// Windows

#else
// Linux

#include <termios.h>
#include <stdio.h>

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

#endif
