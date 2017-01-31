
namespace RGrunt_Dead
{
const string g_szDefaultModel = "models/rgrunt.mdl";

enum BodyGroup
{
	BODYGROUP_BODY = 0,
	BODYGROUP_HEADS,
	BODYGROUP_WEAPONS
}

enum WeaponSubModel
{
	WEAPMDL_M16 = 0,
	WEAPMDL_SHOTGUN,
	WEAPMDL_NONE
}

class monster_rgrunt_dead : ScriptBaseMonsterEntity
{
	/*
	* Settings
	*/
	private string m_szPose;
	
	private float m_flGlowActiveTime = 1;	//How long glow is active for
	private float m_flGlowWaitTime = 2;		//Time between glow turning off and turning on again
	private float m_flMinSparkDelay = 1;	//Minimum delay between sparks
	private float m_flMaxSparkDelay = 2;	//Maximum delay between sparks
	
	private bool m_bDealDamage = false;
	
	private bool m_bDestructible = false;
	
	/*
	* Internal state
	*/
	private bool m_bGlowing;
	
	private float m_flSparkWait;
	private float m_flTurnOffWait;
	private float m_flNextGlowTime;
	
	private float m_flLastDmgTime;
	
	private float m_flDamage;
	
	private int m_iCompGibs;
	private int m_iTailGibs;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "pose" )
		{
			m_szPose = szValue;
			return true;
		}
		else if( szKey == "glowactivetime" )
		{
			m_flGlowActiveTime = atof( szValue );
			return true;
		}
		else if( szKey == "glowwaittime" )
		{
			m_flGlowWaitTime = atof( szValue );
			return true;
		}
		else if( szKey == "minsparkdelay" )
		{
			m_flMinSparkDelay = atof( szValue );
			return true;
		}
		else if( szKey == "maxsparkdelay" )
		{
			m_flMaxSparkDelay = atof( szValue );
			return true;
		}
		else if( szKey == "dealdamage" )
		{
			m_bDealDamage = atoi( szValue ) != 0;
			return true;
		}
		else if( szKey == "destructible" )
		{
			m_bDestructible = atoi( szValue ) != 0;
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Precache()
	{
		BaseClass.Precache();
		
		g_SoundSystem.PrecacheSound( "debris/beamstart14.wav" );
		
		if( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel( self, g_szDefaultModel );
		else
			g_Game.PrecacheModel( self, self.pev.model );
			
		m_iCompGibs = g_Game.PrecacheModel( self, "models/computergibs.mdl" );
		m_iTailGibs = g_Game.PrecacheModel( self, "models/chromegibs.mdl" );
	}
	
	void Spawn()
	{
		Precache();
		
		if( string( self.pev.model ).IsEmpty() )
			g_EntityFuncs.SetModel( self, g_szDefaultModel );
		else
			g_EntityFuncs.SetModel( self, self.pev.model );
			
		g_EntityFuncs.SetSize( self.pev, Vector( -36, -16, 0 ), Vector( 36, 16, 16 ) );
		
		//MonsterInitDead resets this
		const float flHealth = self.pev.health;
		
		//MonsterInitDead sets up some stuff that we'll change below
		self.MonsterInitDead();
		
		self.pev.health = flHealth;
			
		//Allow custom health
		//Note: dead monsters require that at least this much damage is applied in one attack in order to gib the corpse
		if( self.pev.health == 0 )
			self.pev.health = 8;
			
		self.m_bloodColor 		= DONT_BLEED;
		self.pev.solid 			= SOLID_SLIDEBOX;
		self.pev.movetype 		= MOVETYPE_STEP;
		self.pev.takedamage 	= m_bDestructible ? DAMAGE_YES : DAMAGE_NO;
		
		if( self.pev.dmg == 0 )
			m_flDamage = 25;
		else
			m_flDamage = self.pev.dmg;
		
		self.m_FormattedName = "Dead Robo Grunt";
			
		//Check if it's a sequence name
		int iSequence = self.LookupSequence( m_szPose );
		
		//Not a sequence name, or invalid name
		//Try using it as a sequence index
		if( iSequence == -1 )
			iSequence = atoi( m_szPose );
			
		self.pev.sequence = iSequence;
		
		m_bGlowing = false;
		
		//If min and max are both -1, disable
		if( m_flMinSparkDelay == m_flMaxSparkDelay && m_flMaxSparkDelay == -1 )
			m_flSparkWait = -1;
		else
			m_flSparkWait = g_Engine.time + 1;
		
		if( m_flGlowWaitTime == -1 )
			m_flNextGlowTime = -1;
		else
			m_flNextGlowTime = g_Engine.time + m_flGlowWaitTime;
		
		//Disable weapon submodel
		self.SetBodygroup( BODYGROUP_WEAPONS, WEAPMDL_NONE );
		
		self.pev.nextthink = 0.1;
	}
	
	int Classify()
	{
		return CLASS_MACHINE;
	}
	
	void Think()
	{
		self.pev.nextthink = 0.1;
		
		if( IsGlowing() )
		{
			SetTouch ( @::TouchFunction( this.ShockTouch ) );
			
			if( m_flTurnOffWait != -1 && m_flTurnOffWait < g_Engine.time )
			{
				GlowEffect( false ); //Turn glow off
				
				m_flNextGlowTime = g_Engine.time + m_flGlowWaitTime;
			}
		}
		else
		{
			SetTouch( null );
		}
										
		if( m_flSparkWait != -1 && m_flSparkWait <= g_Engine.time )
		{
			Vector vecMins, vecMaxs;
			
			self.ExtractBbox( self.pev.sequence, vecMins, vecMaxs );
			
			const Vector vecSrc = Vector( 	Math.RandomFloat( vecMins.x, vecMaxs.x ), 
											Math.RandomFloat( vecMins.y, vecMaxs.y ), 
											Math.RandomFloat( vecMins.z, 0 ) );
										
			g_Utility.Sparks( vecSrc + self.pev.origin );
			
			PlaySparkSound();
			
			m_flSparkWait = g_Engine.time + Math.RandomFloat( m_flMinSparkDelay, m_flMaxSparkDelay );
		}

		UpdateGlow();
	}
	
	void ShockTouch( CBaseEntity@ pOther )
	{
		if( !m_bDealDamage )
			return;
			
		if( pOther is null )
			return;
			
		if( m_flLastDmgTime + 1 > g_Engine.time )
			return;
			
		m_flLastDmgTime = g_Engine.time;
			
		pOther.TakeDamage( self.pev, self.pev, m_flDamage, DMG_SHOCK );
	}
	
	void GibMonster()
	{
		//Override to prevent organic corpse handling
		
		const Vector vecPosition = self.pev.origin;
		
		//Throw metal gibs
		NetworkMessage metalGibs( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecPosition );
			metalGibs.WriteByte( TE_BREAKMODEL);
			// position
			metalGibs.WriteCoord( vecPosition.x );
			metalGibs.WriteCoord( vecPosition.y );
			metalGibs.WriteCoord( vecPosition.z );
			// size
			metalGibs.WriteCoord( 200 );
			metalGibs.WriteCoord( 200 );
			metalGibs.WriteCoord( 64 );
			// velocity
			metalGibs.WriteCoord( 10 );
			metalGibs.WriteCoord( 20 );
			metalGibs.WriteCoord( 80 );
			// randomization
			metalGibs.WriteByte( 30 ); 
			// Model
			metalGibs.WriteShort( m_iCompGibs );	//model id#
			// # of shards
			metalGibs.WriteByte( 15 );
			// duration
			metalGibs.WriteByte( 100 );// 5.0 seconds
			// flags
			metalGibs.WriteByte( BREAK_METAL );
		metalGibs.End();
		
		//Throw metal gibs
		NetworkMessage tailGibs( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, self.pev.origin );
			tailGibs.WriteByte( TE_BREAKMODEL);
			// position
			tailGibs.WriteCoord( vecPosition.x );
			tailGibs.WriteCoord( vecPosition.y );
			tailGibs.WriteCoord( vecPosition.z );
			// size
			tailGibs.WriteCoord( 200 );
			tailGibs.WriteCoord( 200 );	
			tailGibs.WriteCoord( 96 ); 
			// velocity
			tailGibs.WriteCoord( 0 ); 
			tailGibs.WriteCoord( 0 );
			tailGibs.WriteCoord( 10 );
			// randomization
			tailGibs.WriteByte( 30 ); 
			// Model
			tailGibs.WriteShort( m_iTailGibs );	//model id#
			// # of shards
			tailGibs.WriteByte( 15 );
			// duration
			tailGibs.WriteByte( 100 );// 5.0 seconds
			// flags
			tailGibs.WriteByte( BREAK_METAL );
		tailGibs.End();
		
		g_EntityFuncs.CreateExplosion( self.pev.origin, g_vecZero, null, 100, true );
	}
	
	void PlaySparkSound()
	{
		const int random_pitch = 95 + Math.RandomLong( 0, 10 );
				
		switch( Math.RandomLong( 1, 2 ) )
		{		
			case 1: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "buttons/spark5.wav", .5, ATTN_NORM, 0, random_pitch ); break;		
			case 2: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "buttons/spark6.wav", .5, ATTN_NORM, 0, random_pitch ); break;	
			default: break;
		}
	}
	
	bool IsGlowing() const
	{
		return m_bGlowing;
	}
	
	void GlowEffect( const bool bMode ) final
	{
		if( bMode ) //Turn on
		{	
			self.pev.rendermode 	= kRenderNormal;
			self.pev.renderfx 		= kRenderFxGlowShell;
			self.pev.renderamt 		= 4;
			self.pev.rendercolor 	= Vector( 100, 100, 220 );
		}
		else //Turn off
		{
			self.pev.rendermode 	= kRenderNormal;
			self.pev.renderfx 		= kRenderFxNone;
			self.pev.renderamt 		= 255;
			self.pev.rendercolor 	= Vector(0, 0, 0 );
		}
		
		m_bGlowing = bMode;
	}
	
	void UpdateGlow()
	{
		if( m_flNextGlowTime != -1 && m_flNextGlowTime < g_Engine.time && Math.RandomLong( 0, 30 ) >= 27 )
		{
			if( !IsGlowing() )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_STATIC, "debris/beamstart14.wav", 0.8, ATTN_NORM );
				GlowEffect( true ); //Turn glow on

				//seconds before stopping effect
				m_flTurnOffWait = m_flGlowActiveTime != -1 ? g_Engine.time + m_flGlowActiveTime : -1;
			}
		}
	}
}
}

void MapInit()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "RGrunt_Dead::monster_rgrunt_dead", "monster_rgrunt_dead" );
}