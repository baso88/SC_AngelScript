#ifndef UTILITY_H
#define UTILITY_H

#include <algorithm>
#include <cstdint>

#include "Platform.h"

/**
*	Clamps a given value to a given range.
*/
template<typename T>
T clamp( const T& value, const T& min, const T& max )
{
	return std::max( min, std::min( max, value ) );
}

/**
*	Returns a 1 bit at the given position.
*/
inline constexpr int32_t Bit( const size_t shift )
{
	return static_cast<int32_t>( 1 << shift );
}

/**
*	Returns a 1 bit at the given position.
*	64 bit variant.
*/
inline constexpr int64_t Bit64( const size_t shift )
{
	return static_cast<int64_t>( static_cast<int64_t>( 1 ) << shift );
}

/**
*	Sizeof for array types. Only works for arrays with a known size (stack buffers).
*	@tparam T Array type. Automatically inferred.
*	@tparam SIZE Number of elements in the array.
*	@return Number of elements in the array.
*/
template<typename T, const size_t SIZE>
constexpr inline size_t _ArraySizeof( T( &)[ SIZE ] )
{
	return SIZE;
}

/**
*	Replaces ARRAYSIZE. ARRAYSIZE is defined in some platform specific headers.
*/
#define ARRAYSIZE _ArraySizeof

#define MAX_BUFFER_LENGTH 512

#endif // UTILITY_H
