#include "CHTMLBody.h"

void CHTMLBody::GenerateHTML( std::stringstream& stream )
{
	stream << "<body>" << std::endl;

	CHFI.IncIndent();

	CHTMLComposite::GenerateHTML( stream );

	CHFI.DecIndent();

	stream << "</body>" << std::endl;
}