
namespace TriggerObserver
{
enum SpawnFlag
{
	/**
	*	 If set, the trigger will start on
	*/
	SF_TROBS_STARTON = 1 << 0,
}

/**
*	Possible modes for trigger_observer
*/
enum Mode
{
	MODE_FIRST 		= 0,
	
	/**
	*	Search for players in a square.
	*/
	MODE_SQUARE 	= MODE_FIRST,
	
	/**
	*	Search for players in a sphere.
	*/
	MODE_SPHERE,
	
	MODE_LAST 		= MODE_SPHERE
}

/**
*	Here's hoping this model is never renamed or removed.
*/
const string TROBS_MODEL = "models/error.mdl";

class CTriggerObserver : ScriptBaseEntity
{
	private Mode m_Mode = MODE_SQUARE;
	private float m_flRadius = 64;
	
	private bool m_bOn = true;
	
	private Vector m_vecMins, m_vecMaxs;

	/**
	*	The mode that this entity operates on. Defaults to square mode.
	*/
	Mode Mode
	{
		get const { return m_Mode; }
	}
	
	/**
	*	If using sphere mode, this is the sphere's radius. Defaults to 64 units.
	*/
	float Radius
	{
		get const { return m_flRadius; }
	}
	
	bool On
	{
		get const { return m_bOn; }
	}
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "mode" )
		{
			const int iMode = atoi( szValue );
			
			if( iMode >= MODE_FIRST && iMode <= MODE_LAST )
			{
				m_Mode = Mode( iMode );
			}
			
			return true;
		}
		else if( szKey == "radius" )
		{
			m_flRadius = abs( atof( szValue ) );
			
			return true;
		}
		else
		{
			return BaseClass.KeyValue( szKey, szValue );
		}
	}
	
	void Precache()
	{
		BaseClass.Precache();
		
		g_Game.PrecacheModel( self, TROBS_MODEL );
	}
	
	void Spawn()
	{
		Precache();
		
		//Save off so we can toggle later on.
		m_vecMins = pev.mins;
		m_vecMaxs = pev.maxs;
		
		m_bOn = ( pev.spawnflags & SF_TROBS_STARTON ) != 0;
		
		Setup( m_bOn );
		
		//This must be done after setup because the engine will only insert this entity into the list of triggerable entities if it has a model.
		g_EntityFuncs.SetOrigin( self, pev.origin );
	}
	
	private void Setup( const bool bOn )
	{
		if( m_Mode == MODE_SQUARE )
		{
			if( bOn )
			{
				//Set an invisible model so we are considered for triggering.
				g_EntityFuncs.SetModel( self, TROBS_MODEL );
				g_EntityFuncs.SetSize( pev, m_vecMins, m_vecMaxs );
				
				pev.solid = SOLID_TRIGGER;
				pev.effects |= EF_NODRAW;
				
				SetTouch( TouchFunction( this.SquareTouch ) );
				
				g_EntityFuncs.SetOrigin( self, pev.origin );
			}
			else
			{
				g_EntityFuncs.SetSize( pev, g_vecZero, g_vecZero );
				
				pev.solid = SOLID_NOT;
				
				SetTouch( null );
			}
		}
		else if( m_Mode == MODE_SPHERE )
		{
			pev.solid = SOLID_NOT;
			
			if( bOn )
			{
				SetThink( ThinkFunction( this.SphereThink ) );
				pev.nextthink = g_Engine.time + 0.1f;
			}
			else
			{
				SetThink( null );
				pev.nextthink = 0;
			}
		}
		else
		{
			g_Game.AlertMessage( at_console, "%1(%2): Unknown mode %3, removing self!\n", self.GetClassname(), self.GetTargetname(), m_Mode );
		}
	}
	
	/**
	*	Shunts a player into observer mode if they're not already one.
	*/
	void MakeObserver( CBasePlayer@ pPlayer )
	{
		if( pPlayer is null )
			return;
			
		if( !pPlayer.GetObserver().IsObserver() )
		{
			pPlayer.GetObserver().StartObserver( pPlayer.pev.origin, pPlayer.pev.angles, false );
			
			g_EntityFuncs.FireTargets( pev.target, pPlayer, self, USE_TOGGLE );
		}
	}
	
	/**
	*	Called in square mode; checks if the entity is a player and shunts him/her into observer mode.
	*/
	private void SquareTouch( CBaseEntity@ pOther )
	{
		if( pOther is null || !pOther.IsPlayer() )
			return;
			
		MakeObserver( cast<CBasePlayer@>( pOther ) );
	}
	
	/**
	*	Checks if any players are close enough to be shunted into observer mode.
	*/
	private void SphereThink()
	{
		/*
		*	Enumerating all players is much faster than using g_EntityFuncs.FindEntitiesInSphere, at the cost of only working for players.
		*	Shouldn't be necessary for monsters, but if so, change it.
		*/
		for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
			
			if( pPlayer is null || !pPlayer.IsConnected() )
				continue;
				
			if( ( pPlayer.pev.origin - pev.origin ).Length() > m_flRadius )
				continue;
				
			MakeObserver( pPlayer );
		}
	
		pev.nextthink = g_Engine.time + 0.1f;
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		const bool bOn = m_bOn;
	
		switch( useType )
		{
		case USE_ON: m_bOn = true; break;
		case USE_OFF: m_bOn = false; break;
		case USE_TOGGLE: m_bOn = !m_bOn; break;
		default: return;
		}
		
		if( m_bOn == bOn )
			return;
			
		Setup( m_bOn );
	}
}

/**
*	Registers the trigger_observer entity.
*	@param szOverrideName If not empty, this is the name that will be used for the entity instead of trigger_observer.
*/
void RegisterTriggerObserver( string szOverrideName = "" )
{
	szOverrideName.Trim();
	//Don't forget the namespace!
	g_CustomEntityFuncs.RegisterCustomEntity( "TriggerObserver::CTriggerObserver", szOverrideName.IsEmpty() ? "trigger_observer" : szOverrideName );
}
}