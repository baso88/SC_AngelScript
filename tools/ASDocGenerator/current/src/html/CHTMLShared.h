#ifndef ANGELSCRIPT_CHTMLSHARED_H
#define ANGELSCRIPT_CHTMLSHARED_H

#include <vector>
#include <memory>
#include <string>

enum
{
	HTMLF_UNPAIRED = ( 1 << 0 ),
	HTMLF_NL_OPEN = ( 1 << 1 )
};

class CHTMLFormat
{
public:
	const static uint32_t MAX_INDENT = 10;
	
private:
	CHTMLFormat()
	{
		m_nIndent = 0;
		m_bIndentEnabled = true;
	}

public:
	CHTMLFormat( CHTMLFormat const& ) = delete;
	void operator=( CHTMLFormat const& ) = delete;

	static CHTMLFormat& getInstance()
	{
		static CHTMLFormat instance;
		return instance;
	}

	uint32_t GetIndent() { return m_bIndentEnabled ? m_nIndent : 0; }
	void IncIndent() { if ( m_nIndent < MAX_INDENT ) m_nIndent++; }
	void DecIndent() { if ( m_nIndent > 0 ) m_nIndent--; }
	void ResetIndent() { m_nIndent = 0; }
	void DisableIndent() { m_bIndentEnabled = false; }
	void EnableIndent() { m_bIndentEnabled = true; }

	std::string IndentStr()
	{
		return std::string( GetIndent(), '\t' );
	}

	void ResetAll()
	{
		ResetIndent();
	}

	struct ReplacePair_t final
	{
		const char cChar;
		const char* const pszReplacement;
	};

	const ReplacePair_t m_replacePairs[3] =
	{
		{ '\n', "<br>" },
		{ '<', "&lt;" },
		{ '>', "&gt;" }
	};

	const char * GetReplaceString( char c )
	{
		for ( int i = 0; i < sizeof( m_replacePairs ) / sizeof( ReplacePair_t ); i++ )
		{
			const ReplacePair_t * pPair = &m_replacePairs[ i ];
			if ( c == pPair->cChar )
				return pPair->pszReplacement;
		}

		return nullptr;
	}

	std::string ReplaceSpecialChars( const std::string &in )
	{
		std::string out;
		
		for ( size_t pos = 0; pos < in.length(); pos++ )
		{
			const char * pszReplace = GetReplaceString( in[ pos ] );
			if ( pszReplace )
				out += pszReplace;
			else
				out += in[ pos ];
		}

		return out;
	}

	void ReplaceSubstring( std::string &in, const std::string &search, const std::string &replace )
	{
		for ( size_t pos = 0; ; pos += replace.length() )
		{
			// Locate the substring
			pos = in.find( search, pos );
			if ( pos == std::string::npos )
				break;
			// Replace it
			in.erase( pos, search.length() );
			in.insert( pos, replace );
		}
	}

	std::string FormatString( const std::string &in )
	{
		return ReplaceSpecialChars( in );
	}

	std::string GetFirstLine( const std::string &in, bool bHTML = false )
	{
		std::string out;
		size_t pos = bHTML ? in.find( "<br>" ) : in.find( '\n' );
		if ( pos == std::string::npos )
			out = in;
		else
			out = in.substr( 0, pos );
		return out;
	}

	std::string FormatFirstLine( const std::string &in, bool bHTML = false )
	{
		return FormatString( GetFirstLine( in, bHTML ) );
	}

private:
	uint32_t	m_nIndent;
	bool		m_bIndentEnabled;
	
};

#define CHFI CHTMLFormat::getInstance()

#endif // ANGELSCRIPT_CHTMLSHARED_H