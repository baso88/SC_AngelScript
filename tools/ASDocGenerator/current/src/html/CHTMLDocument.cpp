#include "CHTMLDocument.h"

#include <cassert>
#include <sstream>

#include "IHTMLObject.h"
#include "CHTMLHeader.h"
#include "CHTMLBody.h"

CHTMLDocument::CHTMLDocument()
	: m_Header( new CHTMLHeader() ),
	m_Body( new CHTMLBody() )
{
}

std::string CHTMLDocument::GenerateHTML()
{
	std::stringstream stream;

	stream << "<!DOCTYPE html>" << std::endl;
	stream << "<html>" << std::endl;
	m_Header->GenerateHTML( stream );
	m_Body->GenerateHTML( stream );
	stream << "</html>" << std::endl;

	return stream.str();
}