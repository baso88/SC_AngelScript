#include "utility/Shareddefs.h"
#include "CHTMLElement.h"

#include "CHTMLHeader.h"

CHTMLHeader::CHTMLHeader()
	: m_Title( new CHTMLElement( "title" ) )
	, m_Description( new CHTMLElement( "meta", "", HTMLF_UNPAIRED ) )
	, m_StyleSheet( new CHTMLElement( "link", "", HTMLF_UNPAIRED ) )
{
	m_Description->SetAttributeValue( "name", "description" );
	m_StyleSheet->SetAttributeValue( "rel", "stylesheet" );
	m_StyleSheet->SetAttributeValue( "type", "text/css" );
}

void CHTMLHeader::GenerateHTML( std::stringstream& stream )
{
	stream << CHFI.IndentStr() << "<head>" << std::endl;
	
	CHFI.IncIndent();
	
	stream << CHFI.IndentStr() << "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\">" << std::endl;

	stream << CHFI.IndentStr() << "<meta name=\"generator\" content=\"" << APP_NAME_VER << "\">" << std::endl;

	if( !m_Description->GetAttributeValue( "value" ).empty() )
	{
		m_Description->GenerateHTML( stream );
	}

	if( !m_StyleSheet->GetAttributeValue( "href" ).empty() )
	{
		m_StyleSheet->GenerateHTML( stream );
	}

	m_Title->GenerateHTML( stream );

	CHFI.DecIndent();

	stream << "</head>" << std::endl;
}