#include "CHTMLElement.h"

const std::string CHTMLElement::DEFAULT_ATTRIBUTE_VALUE = "";

CHTMLElement::CHTMLElement( const std::string& szTagName, const std::string& szTextContents, uint32_t flags )
	: m_szTagName( szTagName ),
	m_flags( flags )
{
	SetTextContents( szTextContents );
}

void CHTMLElement::GenerateHTML( std::stringstream& stream )
{
	stream << CHFI.IndentStr() << '<' << m_szTagName;

	if( !m_szAttributes.empty() )
	{
		for( auto& attr : m_szAttributes )
		{
			stream << ' ' << attr.first << "=\"" << attr.second << '\"';
		}
	}

	stream << '>';

	if ( m_flags & HTMLF_NL_OPEN )
	{
		stream << std::endl;
		CHFI.EnableIndent();
		CHFI.IncIndent();
	}
	else
	{
		CHFI.DisableIndent();
	}

	CHTMLComposite::GenerateHTML( stream );

	stream << m_szTextContents;

	if ( m_flags & HTMLF_NL_OPEN )
	{
		CHFI.DecIndent();
		CHFI.EnableIndent();
	}
	
	if ( !(m_flags & HTMLF_UNPAIRED ) )
	{
		stream << CHFI.IndentStr() << "</" << m_szTagName << '>' << std::endl;
	}
	else
	{
		stream << std::endl;
	}

	CHFI.EnableIndent();
}

const std::string& CHTMLElement::GetAttributeValue( const std::string& szAttribute )
{
	auto it = m_szAttributes.find( szAttribute );

	return ( it != m_szAttributes.end() ? it->second : DEFAULT_ATTRIBUTE_VALUE );
}

void CHTMLElement::SetAttributeValue( const std::string& szAttribute, const std::string& szValue )
{
	m_szAttributes.insert( std::make_pair( szAttribute, szValue ) );
}

void CHTMLElement::ClearAttribute( const std::string& szAttribute )
{
	auto it = m_szAttributes.find( szAttribute );

	if( it != m_szAttributes.end() )
		m_szAttributes.erase( it );
}