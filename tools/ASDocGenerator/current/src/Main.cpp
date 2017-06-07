#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "utility/Shareddefs.h"
#include "utility/Logging.h"
#include "utility/Utility.h"

#include "CDocGenerator.h"

//Implement the default log listener.
class CPrintfLogListener final : public ILogListener
{
public:
	void LogMessage( const LogType type, const char* const pszMessage ) override final
	{
		printf( "%s%s", GetLogTypePrefix( type ), pszMessage );
	}
};

namespace
{
static CPrintfLogListener g_PrintfLogListener;
}

/**
*	Describes an application argument.
*/
struct AppArg_t
{
	const char* const	pszName;
	const char* const	pszLongName;
	const bool			bHasValue;
	const char* const	pszDescription;
	const char**		ppszDestination;
};

void PrintUsage( const AppArg_t* const pArgs, const size_t uiNumArgs )
{
	assert( pArgs );

	Message( "Usage:\n" );

	for( size_t uiIndex = 0; uiIndex < uiNumArgs; ++uiIndex )
	{
		const auto& arg = pArgs[ uiIndex ];

		Message( "  %s, %s\n", arg.pszName, arg.pszLongName );
		Message( "    %s\n", arg.pszDescription );
	}

	Message( "\n" );
}

int main( int iArgc, char* pszArgv[] )
{
	// Set up the logger
	SetDefaultLogListener( &g_PrintfLogListener );

	const char * cszArgPresent = "\1";

	const char* pszInputFilename = nullptr;
	const char* pszOutputDirectory = nullptr;
	const char* pszHelp = nullptr;
	const char* pszWait = nullptr;

	AppArg_t args[] = 
	{
		{ "-i", "--inputfile", true, "Name of the file that contains the documentation to convert to HTML", &pszInputFilename },
		{ "-o", "--outputdir", true, "Path to the directory where the HTML files will be saved to", &pszOutputDirectory },
		{ "-h", "--help", false, "Shows this help page", &pszHelp },
		{ "-w", "--wait", false, "The program will wait for any key after finishing", &pszWait }
	};

	/**
	*	Parse in all arguments.
	*/
	for( int iArg = 1; iArg < iArgc; ++iArg )
	{
		for( size_t uiIndex = 0; uiIndex < ARRAYSIZE( args ); ++uiIndex )
		{
			auto& arg = args[ uiIndex ];

			if( strcmp( arg.pszName, pszArgv[ iArg ] ) == 0 ||
				strcmp( arg.pszLongName, pszArgv[ iArg ] ) == 0 )
			{
				if ( arg.bHasValue )
				{
					if( iArg + 1 < iArgc )
					{
						*arg.ppszDestination = pszArgv[ ++iArg ];
					}
				}
				else
				{
					*arg.ppszDestination = cszArgPresent;
				}
			}
		}
	}

	Message( "%s (appver %s, docver %d)\n", APP_NAME_LONG, APP_VER, CDocGenerator::AS_DOCS_VER );

	int iReturnCode = EXIT_SUCCESS;

	if ( iArgc <= 1 || pszHelp != nullptr )
	{
		PrintUsage( args, ARRAYSIZE( args ) );
	}
	else if ( !pszInputFilename )
	{
		Error( "Input file not specified. Use -h or --help to print help page.\n" );
		iReturnCode = EXIT_FAILURE;
	}
	else if ( !pszOutputDirectory )
	{
		Error( "Output directory not specified. Use -h or --help to print help page.\n" );
		iReturnCode = EXIT_FAILURE;
	}
	else
	{
		CDocGenerator generator;
		if( !generator.GenerateFromFile( pszInputFilename, pszOutputDirectory ) )
			iReturnCode = EXIT_FAILURE;
	}

	if( pszWait != nullptr )
	{
		Message( "Press any key to continue..." );
		getch();
	}

	return iReturnCode;
}