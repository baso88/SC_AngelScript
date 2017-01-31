/**
*	@file
*
*	A deployable entity weapon.
*/

/**
*	Default delay between primary attacks.
*/
const float DEPLOY_DEFAULT_PRIMARY_ATTACK_DELAY = 0.1f;

/**
*	Default delay between primary attacks.
*/
const float DEPLOY_DEFAULT_SECONDARY_ATTACK_DELAY = 0.1f;

/**
*	Default maximum deployment distance.
*/
const float DEPLOY_DEFAULT_MAX_DISTANCE = 128;

/**
*	Default entity to deploy.
*/
const string DEPLOY_DEFAULT_ENTITY = "monster_sentry";

/**
*	Default entity health.
*/
const float DEPLOY_DEFAULT_HEALTH = 0;

/**
*	The userdata key for deploy data.
*/
const string DEPLOY_USERDATA_KEY = "DEPLOY_DATA";

/**
*	Deploy data stored by entity user data.
*/
class CDeployData
{
	/**
	*	Player that deployed the entity.
	*/
	EHandle m_hPlayer;
	
	/**
	*	Entity that did the deploying (weapon_deployentity instance).
	*/
	EHandle m_hDeployer;
}

class weapon_deployentity : ScriptBasePlayerWeaponEntity
{
	private string m_szEntityClassname = DEPLOY_DEFAULT_ENTITY;
	
	private float m_flHealth = DEPLOY_DEFAULT_HEALTH;

	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "entity_classname" )
		{
			m_szEntityClassname = szValue;
			return true;
		}
		else if( szKey == "target_health" )
		{
			m_flHealth = atof( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		
		g_Game.PrecacheModel( self, "models/v_pipe_wrench.mdl" );
		g_Game.PrecacheModel( self, "models/w_pipe_wrench.mdl" );
		g_Game.PrecacheModel( self, "models/p_pipe_wrench.mdl" );
		
		g_Game.PrecacheMonster( m_szEntityClassname, true );
	}
	
	void Spawn()
	{
		self.Precache();
		
		g_EntityFuncs.SetModel( self, "models/w_pipe_wrench.mdl" );
		self.FallInit();// get ready to fall
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= WEAPON_NOCLIP;
		info.iMaxAmmo2 	= WEAPON_NOCLIP;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot 		= 5;
		info.iPosition 	= 6;
		info.iFlags 	= 0;
		info.iWeight 	= -5;

		return true;
	}
	
	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/v_pipe_wrench.mdl" ), self.GetP_Model( "models/p_pipe_wrench.mdl" ), 1, "crowbar" );
	}
	
	void PrimaryAttack()
	{
		self.m_flNextPrimaryAttack = WeaponTimeBase() + DEPLOY_DEFAULT_PRIMARY_ATTACK_DELAY;
		
		TraceResult tr;
		
		Math.MakeVectors( self.m_pPlayer.pev.v_angle );
		
		const Vector vecStart = self.m_pPlayer.GetOrigin() + self.m_pPlayer.pev.view_ofs;
		
		//See where we should place the entity.
		g_Utility.TraceLine( vecStart, vecStart + g_Engine.v_forward * DEPLOY_DEFAULT_MAX_DISTANCE, ignore_monsters, self.m_pPlayer.edict(), tr );
		
		//Couldn't find anywhere to put it.
		if( tr.flFraction == 1.0 )
		{
			return;
		}
		
		if( tr.fAllSolid != 0 )
		{
			g_Game.AlertMessage( at_console, "Couldn't create deployable \"%1\": stuck in solid\n", m_szEntityClassname );
			return;
		}
		
		//Inherit player angles.
		CBaseEntity@ pEntity = g_EntityFuncs.Create( m_szEntityClassname, tr.vecEndPos + Vector( 0, 0, 8 ), Vector( 0, self.m_pPlayer.pev.angles.y, 0 ), true/*, self.m_pPlayer.edict()*/ );
		
		if( pEntity is null )
		{
			g_Game.AlertMessage( at_console, "Couldn't create deployable \"%1\": entity could not be created\n", m_szEntityClassname );
			return;
		}
		
		//Get the player's classification, defaulting to CLASS_PLAYER_ALLY so the turret is always allied to _this_ player.
		pEntity.SetClassification( self.m_pPlayer.Classify() );
		//Always a player ally. Call after setting class because setting class overwrites this.
		pEntity.SetPlayerAllyDirect( true );
		
		//Health == 0 means use default health.
		if( m_flHealth > 0 )
		{
			//Set a health that lets it survive to deploy itself.
			pEntity.pev.health = m_flHealth;
		}
		
		if( g_EntityFuncs.DispatchSpawn( pEntity.edict() ) == -1 )
		{
			g_Game.AlertMessage( at_console, "Deployed entity was removed\n" );
			return;
		}
		
		if( g_EngineFuncs.DropToFloor( pEntity.edict() ) == -1 )
		{
			g_Game.AlertMessage( at_console, "Deployed entity is stuck in the world, removing\n" );
			g_EntityFuncs.Remove( pEntity );
			return;
		}
		
		//Attach deployment data.
		CDeployData data;
		
		data.m_hPlayer = self.m_pPlayer;
		data.m_hDeployer = self;
		
		pEntity.GetUserData().set( DEPLOY_USERDATA_KEY, @data );
	}
	
	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = WeaponTimeBase() + DEPLOY_DEFAULT_SECONDARY_ATTACK_DELAY;
		
		CBaseEntity@ pEntity = g_Utility.FindEntityForward( self.m_pPlayer );
		
		if( pEntity is null || !pEntity.pev.ClassNameIs( m_szEntityClassname ) )
		{
			return;
		}
		
		CDeployData@ pData = null;
		
		//Not a deployed entity or not deployed by this entity's owner.
		if( !pEntity.GetUserData().get( DEPLOY_USERDATA_KEY, @pData ) || pData.m_hPlayer.GetEntity() !is self.m_pPlayer )
		{
			return;
		}
		
		g_EntityFuncs.Remove( pEntity );
	}
}

/**
*	Entity classname for this entity.
*/
string GetDeployEntityName()
{
	return "weapon_deployentity";
}

/**
*	Registers the deploy entity weapon.
*/
void RegisterDeployEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_deployentity", GetDeployEntityName() );
	g_ItemRegistry.RegisterWeapon( GetDeployEntityName(), "deployentity" );
}
