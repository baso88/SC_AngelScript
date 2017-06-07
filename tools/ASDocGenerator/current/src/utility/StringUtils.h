#ifndef STDLIB_STRINGUTILS_H
#define STDLIB_STRINGUTILS_H

#include <algorithm>
#include <cstring>

/**
*	Checks if a printf operation was successful
*/
inline bool PrintfSuccess( const int iRet, const size_t uiBufferSize )
{
	return iRet >= 0 && static_cast<size_t>( iRet ) < uiBufferSize;
}

/**
*	Works like strstr, but the substring length is given.
*/
const char* strnstr( const char* pszString, const char* pszSubString, const size_t uiLength );

/**
*	Works like strrstr, but the substring length is given.
*/
const char* strnrstr( const char* pszString, const char* pszSubString, const size_t uiLength );

/**
*	Checks whether a token matches a string.
*	The token can have '*' characters to signal 0 or more characters that can span the space between given characters.
*	@param pszString String to match against.
*	@param pszToken Token to match.
*	@return Whether the token matches.
*/
bool UTIL_TokenMatches( const char* pszString, const char* pszToken );

#endif //STDLIB_STRINGUTILS_H