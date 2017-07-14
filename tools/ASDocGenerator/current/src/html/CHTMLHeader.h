#ifndef HTML_CHTMLHEADER_H
#define HTML_CHTMLHEADER_H

#include <memory>

#include "IHTMLObject.h"

class CHTMLElement;

/**
*	HTML element that represents the \<head\> element.
*/
class CHTMLHeader : public IHTMLObject
{
public:

	// Open Graph
	
	typedef enum
	{
		OGID_TITLE = 0,
		OGID_DESC,
		OGID_TYPE,
		OGID_IMAGE,
		OGID_SITE

	} OGID;

private:

	const static int NUM_OGID = OGID_SITE + 1;

	const std::string OGTypes[ NUM_OGID ] =
	{
		"og:title",
		"og:description",
		"og:type",
		"og:image",
		"og:site_name"
	};

public:

	CHTMLHeader();
	~CHTMLHeader() = default;

	virtual void GenerateHTML( std::stringstream& stream ) override;

	std::shared_ptr<CHTMLElement> GetTitle() const { return m_Title; }
	std::shared_ptr<CHTMLElement> GetDescription() const { return m_Description; }
	std::shared_ptr<CHTMLElement> GetStyleSheet() const { return m_StyleSheet; }
	std::shared_ptr<CHTMLElement> GetOpenGraph( OGID id ) const { return m_OpenGraph[ id ]; }

private:
	std::shared_ptr<CHTMLElement> m_Title, m_Description, m_StyleSheet;
	std::shared_ptr<CHTMLElement> m_OpenGraph[ NUM_OGID ];

private:

	CHTMLHeader( const CHTMLHeader& ) = delete;
	CHTMLHeader& operator=( const CHTMLHeader& ) = delete;
};

#endif //HTML_CHTMLHEADER_H