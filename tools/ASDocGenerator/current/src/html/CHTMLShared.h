#ifndef ANGELSCRIPT_CHTMLSHARED_H
#define ANGELSCRIPT_CHTMLSHARED_H

#include <vector>
#include <memory>
#include <string>

enum
{
	HTMLF_UNPAIRED = ( 1 << 0 ),
	HTMLF_NL_CLOSE = ( 1 << 1 )
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

private:
	uint32_t	m_nIndent;
	bool		m_bIndentEnabled;
	
};

#define CHFI CHTMLFormat::getInstance()

#endif // ANGELSCRIPT_CHTMLSHARED_H