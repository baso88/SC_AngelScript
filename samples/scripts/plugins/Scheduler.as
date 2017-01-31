/*
*	Sven Co-op Angelscript V1.0 Beta
*
* 	This is a sample script showing how to use the scheduler
*
*/

/*
* Simple class to keep track of a counter
*/
class Counter
{
	uint m_uiCounter = 0;
	
	void IncrementAndOutput()
	{
		++m_uiCounter;
		
		g_Game.AlertMessage( at_console, "%1 called %2 times\n", @this, m_uiCounter );
	}
}

CScheduledFunction@ g_pFunc3 = null;

void Function1()
{
	g_Game.AlertMessage( at_console, "Function 1 at %1\n", g_Engine.time );
}

void Function2()
{
	g_Game.AlertMessage( at_console, "Function 2 at %1\n", g_Engine.time );
}

void Function3( Counter@ pCounter )
{
	++pCounter.m_uiCounter;
	g_Game.AlertMessage( at_console, "Function 3 at %1, called %2 times\n", g_Engine.time, pCounter.m_uiCounter );
}

void Function4()
{
	g_Game.AlertMessage( at_console, "Function 4 at %1\n", g_Engine.time );
	
	CScheduledFunction@ pThisFunc = g_Scheduler.GetCurrentFunction();
	
	if( pThisFunc !is null )
	{
		g_Game.AlertMessage( at_console, "Next call time: %1, Repeat time: %2, repeat count: %3\n", pThisFunc.GetNextCallTime(), pThisFunc.GetRepeatTime(), pThisFunc.GetRepeatCount() );
		
		if( pThisFunc.IsInfiniteRepeat() )
			pThisFunc.SetRepeatCount( 2 );
			
		if( g_pFunc3 !is null )
		{
			g_Game.AlertMessage( at_console, "Has been removed: %1\n", g_pFunc3.HasBeenRemoved() );
				
			if( pThisFunc.GetRepeatCount() == 1 )
			{
				//Allow one more execution
				if( g_pFunc3.IsInfiniteRepeat() )
					g_pFunc3.SetRepeatCount( 1 );
			}
			
			if( g_pFunc3.HasBeenRemoved() )
				@g_pFunc3 = null;
		}
	}
}

/*
* Set up some functions to be called
*/
void PluginInit()
{
	//Set plugin info
	g_Module.ScriptInfo.SetAuthor( "Sven Co-op Development Team" );
	g_Module.ScriptInfo.SetContactInfo( "www.svencoop.com" );
	
	//Call Function1 with no parameters after 5 seconds
	g_Scheduler.SetTimeout( "Function1", 5 );
	
	//Call Function2 with no parameters after 5 seconds, repeating 10 times, with an interval of 5 seconds
	g_Scheduler.SetInterval( "Function2", 5, 10 );
	
	//Call Function3 with a counter after 3 seconds, repeating an infinite number of times, with an interval of 3 seconds
	@g_pFunc3 = @g_Scheduler.SetInterval( "Function3", 3, g_Scheduler.REPEAT_INFINITE_TIMES, @Counter() );
	
	//Call Function4 after 10 seconds, repeating an infinite number of times, with an interval of 10 seconds
	g_Scheduler.SetInterval( "Function4", 10, g_Scheduler.REPEAT_INFINITE_TIMES );
	
	//Call object method IncrementAndOutput on the counter instance after 1 second, repeating 5 times, with an interval of 1 second
	g_Scheduler.SetInterval( @Counter(), "IncrementAndOutput", 1, 5 );
}