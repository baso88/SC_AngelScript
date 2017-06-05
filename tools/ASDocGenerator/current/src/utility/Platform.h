#ifndef PLATFORM_H
#define PLATFORM_H

#ifdef WIN32
// Windows

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <Windows.h>

#include <direct.h>

#undef GetCurrentTime
#undef ARRAYSIZE

#define MAX_PATH_LENGTH MAX_PATH

#define strcasecmp _stricmp
#define strncasecmp _strnicmp

#define getcwd _getcwd
#define setcwd _chdir

#undef getch
#undef getche

#define getch _getch
#define getche _getche

#else
// Linux

#include <linux/limits.h>
#include <strings.h>

#define MAX_PATH PATH_MAX
#define MAX_PATH_LENGTH PATH_MAX

// Reads 1 character without echo
char getch( void );
// Reads 1 character with echo
char getche( void );

#endif

#endif //PLATFORM_H
