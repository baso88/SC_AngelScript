/*
*	This plugins tracks all player decals
*/

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Sven Co-op Team" );
	g_Module.ScriptInfo.SetContactInfo( "www.svencoop.com" );
	
	//Only admins can use this
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );
	
	g_Hooks.RegisterHook( Hooks::Player::PlayerDecal, @PlayerDecalTracker::PlayerDecalHook );
}

void MapInit()
{
	//Clear all data on new map
	PlayerDecalTracker::g_PlayerDecalTracker.Reset();
}

namespace PlayerDecalTracker
{
const uint g_uiMaxDecals = 64;		//Maximum number of decals to track at any given time

const float g_flLifetime = 120;		//How long a given decal should be tracked

const float g_flMaxDistance = 128;	//How far a player can be from the spray origin and still get info

const int g_iMessageLifeTime = 2;	//How many seconds to keep showing the message after the player has stopped looking at a spray

HookReturnCode PlayerDecalHook( CBasePlayer@ pPlayer, const TraceResult& in trace )
{
	g_PlayerDecalTracker.CreateDecal( pPlayer, trace );
	
	return HOOK_CONTINUE;
}

/*
* Represents a single decal
*/
final class PlayerDecal
{
	private string m_szPlayerName;
	
	private string m_szAuthId;
	
	private Vector m_vecPosition;
	
	private float m_flCreationTime;
	
	/*
	*	Name of the player
	*/
	string PlayerName
	{
		get const { return m_szPlayerName; }
	}
	
	/*
	*	Player Auth Id (Steam ID)
	*/
	string AuthId
	{
		get const { return m_szAuthId; }
	}
	
	/*
	*	Decal origin
	*/
	Vector Position
	{
		get const { return m_vecPosition; }
	}
	
	/*
	*	Time at which this decal was created
	*/
	float CreationTime
	{
		get const { return m_flCreationTime; }
	}
	
	PlayerDecal()
	{
		Reset();
	}
	
	bool Init( CBasePlayer@ pPlayer, const Vector& in vecPosition, const float flCreationTime )
	{
		Reset();
		
		if( pPlayer is null )
			return false;
			
		m_szPlayerName = pPlayer.pev.netname;
		m_szAuthId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
		
		m_vecPosition = vecPosition;
		
		m_flCreationTime = flCreationTime;
		
		return IsValid();
	}
	
	void Reset()
	{
		m_szPlayerName 		= "";
		m_szAuthId 			= "";
		m_vecPosition 		= g_vecZero;
		m_flCreationTime 	= 0;
	}
	
	/*
	*	Is this decal object initialized?
	*/
	bool IsInitialized() const
	{
		return m_flCreationTime > 0;
	}
	
	/*
	*	Has this decal expired?
	*/
	bool HasExpired() const
	{
		return ( m_flCreationTime + g_flLifetime ) < g_Engine.time;
	}
	
	/*
	*	Is this decal valid? (was created by a valid player and not expired yet)
	*/
	bool IsValid() const
	{
		return !HasExpired() && 
				!m_szPlayerName.IsEmpty() && !m_szAuthId.IsEmpty();
	}
}

final class PlayerDecalTracker
{
	private array<PlayerDecal@> m_PlayerDecals;
	
	private array<int> m_iWasLooking;				//Whether a particular player was looking at a decal. 0 based index, subtract 1 from player index.
	
	private CScheduledFunction@ m_pFunction = null;	//Think function
	
	private CCVar@ m_pVisibleLevel;					//Controls visibility level (all players can see this, admin only, owner only)
	
	PlayerDecalTracker()
	{
		m_PlayerDecals.resize( g_uiMaxDecals );
		
		for( uint uiIndex = 0; uiIndex < m_PlayerDecals.length(); ++uiIndex )
			@m_PlayerDecals[ uiIndex ] = @PlayerDecal();
			
		m_iWasLooking.resize( g_Engine.maxClients );
		
		for( uint uiIndex = 0; uiIndex < m_iWasLooking.length(); ++uiIndex )
			m_iWasLooking[ uiIndex ] = 0;
			
		@m_pVisibleLevel = CCVar( "visible_level", ADMIN_NO, "Visibility level for Player Decal Tracker", ConCommandFlag::AdminOnly );
	}
	
	private void VisibleLevelChanged( CCVar@ pCVar, const string& in szOldValue, const float flOldValue )
	{
		//Clamp to valid values
		pCVar.SetInt( Math.min( ADMIN_OWNER, Math.max( ADMIN_NO, pCVar.GetInt() ) ) );
	}
	
	void Reset()
	{
		for( uint uiIndex = 0; uiIndex < m_PlayerDecals.length(); ++uiIndex )
			m_PlayerDecals[ uiIndex ].Reset();
			
		for( uint uiIndex = 0; uiIndex < m_iWasLooking.length(); ++uiIndex )
			m_iWasLooking[ uiIndex ] = 0;
			
		//Reset every map change
		if( m_pFunction !is null )
			g_Scheduler.RemoveTimer( m_pFunction );
			
		//Think every second
		@m_pFunction = g_Scheduler.SetInterval( @this, "Think", 1 );
	}
	
	private PlayerDecal@ FindFreeEntry( const bool bInvalidateOldest )
	{
		PlayerDecal@ pDecal = null;
		
		PlayerDecal@ pOldest = null;
		
		for( uint uiIndex = 0; uiIndex < m_PlayerDecals.length(); ++uiIndex )
		{
			@pDecal = m_PlayerDecals[ uiIndex ];
			
			if( !pDecal.IsValid() )
				return pDecal;
			else if( bInvalidateOldest )
			{
				if( pOldest is null || pOldest.CreationTime > pDecal.CreationTime )
				{
					@pOldest = pDecal;
				}
			}
		}
		
		return pOldest;
	}
	
	private const PlayerDecal@ FindNearestDecal( const Vector& in vecOrigin ) const
	{
		PlayerDecal@ pDecal = null;
		
		PlayerDecal@ pNearest = null;
		
		float flNearestDistance = Math.FLOAT_MAX;
		
		for( uint uiIndex = 0; uiIndex < m_PlayerDecals.length(); ++uiIndex )
		{
			@pDecal = m_PlayerDecals[ uiIndex ];
			
			if( !pDecal.IsValid() )
				continue;
			
			const float flDistance = ( pDecal.Position - vecOrigin ).Length();
				
			if( pNearest is null || flDistance < flNearestDistance )
			{
				flNearestDistance = flDistance;
				@pNearest = pDecal;
			}
		}
		
		return pNearest;
	}
	
	/*
	*	Creates a new decal. The given player is the owner, the given trace result contains position data.
	*/
	void CreateDecal( CBasePlayer@ pPlayer, const TraceResult& in trace )
	{
		if( pPlayer is null )
			return;
			
		PlayerDecal@ pEntry = FindFreeEntry( true );
		
		//This shouldn't ever happen, but still
		if( pEntry is null )
			return;
			
		pEntry.Init( pPlayer, trace.vecEndPos, g_Engine.time );
	}
	
	void Think()
	{
		/*
		*	For every valid player, check if there are nearby decals.
		*/
		for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
			
			if( pPlayer is null || !pPlayer.IsConnected() )
				continue;
				
			//For your eyes only.
			AdminLevel_t adminLevel = g_PlayerFuncs.AdminLevel( pPlayer );
			
			if( adminLevel < m_pVisibleLevel.GetInt() )
				continue;
				
			//Calculate position that the player is looking at.
			const Vector vecEyes = pPlayer.pev.origin + pPlayer.pev.view_ofs;
			
			Vector vec;
			
			{
				Vector vecDummy;
			
				g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vec, vecDummy, vecDummy );
			}
			
			TraceResult tr;
			
			g_Utility.TraceLine( vecEyes, vecEyes + ( vec * WORLD_BOUNDARY ), dont_ignore_monsters, pPlayer.edict(), tr );
			
			bool bWasLooking = false;
			
			//Found valid looking position
			if( tr.flFraction < 1.0 )
			{
				const PlayerDecal@ pNearest = FindNearestDecal( tr.vecEndPos );
				
				//Found a valid decal
				if( pNearest !is null )
				{
					//Is it close enough?
					if( ( pNearest.Position - tr.vecEndPos ).Length() <= g_flMaxDistance )
					{
						bWasLooking = true;
						
						string szMessage;
						
						snprintf( szMessage, "Spray by \n%1 \nAuth ID: %2", pNearest.PlayerName, pNearest.AuthId );
						
						g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, szMessage );
					}
				}
			}
			
			//Reset looking time
			if( bWasLooking )
				m_iWasLooking[ iPlayer - 1 ] = g_iMessageLifeTime;
			else
			{
				if( m_iWasLooking[ iPlayer - 1 ] > 0 )
				{
					//Add a space so multiple messages don't stick together
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, " " );
					
					--m_iWasLooking[ iPlayer - 1 ];
				}
			}
		}
	}
}

PlayerDecalTracker g_PlayerDecalTracker;
}