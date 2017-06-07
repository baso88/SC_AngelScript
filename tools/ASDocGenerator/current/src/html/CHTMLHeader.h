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

	CHTMLHeader();
	~CHTMLHeader() = default;

	virtual void GenerateHTML( std::stringstream& stream ) override;

	std::shared_ptr<CHTMLElement> GetTitle() const { return m_Title; }
	std::shared_ptr<CHTMLElement> GetDescription() const { return m_Description; }
	std::shared_ptr<CHTMLElement> GetStyleSheet() const { return m_StyleSheet; }

private:
	std::shared_ptr<CHTMLElement> m_Title, m_Description, m_StyleSheet;

private:

	CHTMLHeader( const CHTMLHeader& ) = delete;
	CHTMLHeader& operator=( const CHTMLHeader& ) = delete;
};

#endif //HTML_CHTMLHEADER_H