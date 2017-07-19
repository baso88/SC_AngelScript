
// Cyber-Franklin entity for the final battle
// Author: GeckonCZ

#include "franklinhornet"

namespace CyberFranklin
{

const int		CYBERFRANKLIN_AE_RELOAD			= ( 2 );
const int		CYBERFRANKLIN_AE_KICK			= ( 3 );
const int		CYBERFRANKLIN_AE_BURST1			= ( 4 );
const int		CYBERFRANKLIN_AE_BURST2			= ( 5 ); 
const int		CYBERFRANKLIN_AE_BURST3			= ( 6 );
const int		CYBERFRANKLIN_AE_GREN_TOSS		= ( 7 );
const int		CYBERFRANKLIN_AE_GREN_LAUNCH	= ( 8 );
const int		CYBERFRANKLIN_AE_GREN_DROP		= ( 9 );
const int		CYBERFRANKLIN_AE_CAUGHT_ENEMY	= ( 10 ); // grunt established sight with an enemy (player only) that had previously eluded the squad.
const int		CYBERFRANKLIN_AE_DROP_GUN		= ( 11 ); // grunt (probably dead) is dropping his mp5.

const int		CYBERFRANKLIN_HEALTH_BASE		= 400;
const int		CYBERFRANKLIN_HEALTH_PER_PLAYER_INC = 110;

const int		CYBERFRANKLIN_MELEE_DIST		= 100;
const int		CYBERFRANKLIN_DAMAGE_KICK		= 25;

const string	CYBERFRANKLIN_MODEL				= "models/hunger/franklin2.mdl";

class monster_th_cyberfranklin : ScriptBaseMonsterEntity
{
	private float	m_painTime;
	private int		m_head;
	
	private bool	m_fCanHornetAttack;
	private float	m_flNextHornetAttackCheck;
	
	private int		m_iAgruntMuzzleFlash;
	
	monster_th_cyberfranklin( void )
	{
		@this.m_Schedules = @monster_th_cyberfranklin_schedules;
	}
	
	void Spawn( void )
	{
		Precache();
		
		if( !self.SetupModel() )
			g_EntityFuncs.SetModel( self, CYBERFRANKLIN_MODEL );

		g_EntityFuncs.SetSize( self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX );
	
		pev.solid					= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_STEP;
		self.m_bloodColor			= BLOOD_COLOR_RED;
		if( self.pev.health == 0.0f )
		{
			self.pev.health = CYBERFRANKLIN_HEALTH_BASE;
		}
		self.pev.view_ofs			= Vector( 0, 0, 50 );// position of the eyes relative to monster's origin.
		self.m_flFieldOfView		= VIEW_FIELD_WIDE; // NOTE: we need a wide field of view so npc will notice player and say hello
		self.m_MonsterState			= MONSTERSTATE_NONE;
		self.pev.body				= 0;
		self.m_afCapability			= bits_CAP_HEAR | bits_CAP_TURN_HEAD | bits_CAP_DOORS_GROUP | bits_CAP_USE_TANK;

		if( string( self.m_FormattedName ).IsEmpty() )
		{
			self.m_FormattedName = "Cyber-Franklin";
		}

		self.MonsterInit();
	}
	
	void Precache( void )
	{
		BaseClass.Precache();
		
		//Model precache optimization -Sniper
		if( string( self.pev.model ).IsEmpty() )
		{
			g_Game.PrecacheModel(CYBERFRANKLIN_MODEL);
		}

		g_SoundSystem.PrecacheSound("hunger/franklin/pain1.wav");
		g_SoundSystem.PrecacheSound("hunger/franklin/pain2.wav");
		g_SoundSystem.PrecacheSound("hunger/franklin/death1.wav");
		g_SoundSystem.PrecacheSound("hunger/franklin/death2.wav");
		g_SoundSystem.PrecacheSound("hunger/franklin/death3.wav");
		
		g_SoundSystem.PrecacheSound( "svencoop2/weirdlaugh1.wav" );
		
		m_iAgruntMuzzleFlash = g_Game.PrecacheModel( "sprites/muz4.spr" );
		
		// We have to precache the hornet here.
		// It would be to late to precache it's sounds when hornet is spawned.
		g_Game.PrecacheOther( "franklinhornet" );
	}
	
	int ObjectCaps( void )
	{
		if( self.IsPlayerAlly() )
			return FCAP_IMPULSE_USE;
		else
			return BaseClass.ObjectCaps();
	}
	
	void RunTask( Task@ pTask )
	{
		BaseClass.RunTask( pTask );
	}
	
	int ISoundMask()
	{
		return	bits_SOUND_WORLD	|
				bits_SOUND_COMBAT	|
				bits_SOUND_BULLETHIT|
				bits_SOUND_CARCASS	|
				bits_SOUND_MEAT		|
				bits_SOUND_GARBAGE	|
				bits_SOUND_DANGER	|
				bits_SOUND_PLAYER;
	}
	
	int	Classify()
	{
		return self.GetClassification(CLASS_ALIEN_MILITARY);
	}
	
	void SetYawSpeed ()
	{
		int ys = 0;

		/*
		switch ( m_Activity )
		{
		case ACT_TURN_LEFT:
		case ACT_TURN_RIGHT:
			ys = 180;
			break;

		case ACT_IDLE:
		case ACT_WALK: 
			ys = 70;	
			break;
		case ACT_RUN:  
			ys = 90;	
			break;

		default:       
			ys = 70;	
			break;
		}
		*/

		ys = 360; //270 seems to be an ideal speed, which matches most animations

		self.pev.yaw_speed = ys;
	}
	
	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if ( g_Engine.time < m_flNextHornetAttackCheck )
		{
			return m_fCanHornetAttack;
		}

		if ( self.HasConditions( bits_COND_SEE_ENEMY ) && flDist >= CYBERFRANKLIN_MELEE_DIST && flDist <= 1024 && flDot >= 0.5 && self.NoFriendlyFire() )
		{
			TraceResult	tr;
			Vector	vecArmPos, vecArmDir;
			CBaseEntity@ pEnemy = self.m_hEnemy.GetEntity();

			// verify that a shot fired from the gun will hit the enemy before the world.
			// !!!LATER - we may wish to do something different for projectile weapons as opposed to instant-hit
			Math.MakeVectors( pev.angles );
			self.GetAttachment( 0, vecArmPos, vecArmDir );
	//		g_Utility.TraceLine( vecArmPos, vecArmPos + g_Engine.v_forward * 256, ignore_monsters, self.edict(), tr);
			g_Utility.TraceLine( vecArmPos, pEnemy.BodyTarget(vecArmPos), dont_ignore_monsters, self.edict(), tr);

			if ( tr.flFraction == 1.0 || tr.pHit is pEnemy.edict() )
			{
				m_flNextHornetAttackCheck = g_Engine.time + Math.RandomFloat( 2, 5 );
				m_fCanHornetAttack = true;
				return m_fCanHornetAttack;
			}
		}
		
		m_flNextHornetAttackCheck = g_Engine.time + 0.2;// don't check for half second if this check wasn't successful
		m_fCanHornetAttack = false;
		return m_fCanHornetAttack;
	}
	
	bool CheckMeleeAttack1( float flDot, float flDist )
	{
		CBaseMonster@ pEnemy;

		if ( self.m_hEnemy.IsValid() )
		{
			@pEnemy = self.m_hEnemy.GetEntity().MyMonsterPointer();

			if ( pEnemy is null )
			{
				return false;
			}
		}

		if ( flDist <= 64 && flDot >= 0.7 && 
			 pEnemy.Classify() != CLASS_ALIEN_BIOWEAPON &&
			 pEnemy.Classify() != CLASS_PLAYER_BIOWEAPON )
		{
			return true;
		}
		return false;
	}
	
	bool CheckRangeAttack2( float flDot, float flDist )
	{	
		return false;
	}
	
	CBaseEntity@ Kick( void )
	{
		TraceResult tr;

		Math.MakeVectors( pev.angles );
		Vector vecStart = pev.origin;
		vecStart.z += pev.size.z * 0.5;
		Vector vecEnd = vecStart + (g_Engine.v_forward * CYBERFRANKLIN_MELEE_DIST);

		g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, self.edict(), tr );
		
		if ( tr.pHit !is null )
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
			return pEntity;
		}

		return null;
	}
	
	void Shoot( void )
	{
		// m_vecEnemyLKP should be center of enemy body
		Vector vecArmPos, vecArmDir;
		Vector vecDirToEnemy;
		Vector angDir;

		if (self.HasConditions( bits_COND_SEE_ENEMY))
		{
			vecDirToEnemy = ( ( self.m_vecEnemyLKP ) - pev.origin );
			angDir = Math.VecToAngles( vecDirToEnemy );
			vecDirToEnemy = vecDirToEnemy.Normalize();
		}
		else
		{
			angDir = pev.angles;
			Math.MakeAimVectors( angDir );
			vecDirToEnemy = g_Engine.v_forward;
		}

		pev.effects = EF_MUZZLEFLASH;

		// make angles +-180
		if (angDir.x > 180)
		{
			angDir.x = angDir.x - 360;
		}

		self.SetBlending( 0, angDir.x );
		self.GetAttachment( 0, vecArmPos, vecArmDir );

		vecArmPos = vecArmPos + vecDirToEnemy * 32;
		
		
		NetworkMessage message( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecArmPos );
			message.WriteByte(TE_SPRITE);
			message.WriteCoord(vecArmPos.x);
			message.WriteCoord(vecArmPos.y);
			message.WriteCoord(vecArmPos.z);
			message.WriteShort(m_iAgruntMuzzleFlash);
			message.WriteByte(6);
			message.WriteByte(128);
		message.End();

		//CBaseEntity@ pHornet = g_EntityFuncs.CreateEntity( "franklinhornet" );
		CBaseEntity@ pHornet = g_EntityFuncs.Create( "franklinhornet", vecArmPos, Math.VecToAngles( vecDirToEnemy ), false, self.edict() );
		Math.MakeVectors ( pHornet.pev.angles );
		pHornet.pev.velocity = g_Engine.v_forward * 300;
		
		
		
		switch ( Math.RandomLong ( 0 , 2 ) )
		{
			case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "agrunt/ag_fire1.wav", 1.0, ATTN_NORM, 0, 100 );	break;
			case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "agrunt/ag_fire2.wav", 1.0, ATTN_NORM, 0, 100 );	break;
			case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "agrunt/ag_fire3.wav", 1.0, ATTN_NORM, 0, 100 );	break;
		}

		CBaseMonster@ pHornetMonster = pHornet.MyMonsterPointer();

		if ( pHornetMonster !is null )
		{
			pHornetMonster.m_hEnemy = self.m_hEnemy;
		}

		if( self.pev.movetype != MOVETYPE_FLY && self.m_MonsterState != MONSTERSTATE_PRONE )
		{
			self.m_flAutomaticAttackTime = g_Engine.time + Math.RandomFloat(0.2, 0.5);
		}
	}
	
	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
		case CYBERFRANKLIN_AE_BURST1:
		case CYBERFRANKLIN_AE_BURST2:
		case CYBERFRANKLIN_AE_BURST3:
			Shoot();
			break;
			
		case CYBERFRANKLIN_AE_KICK:
		{
			CBaseEntity@ pHurt = Kick();

			if ( pHurt !is null )
			{
				// SOUND HERE!
				Math.MakeVectors( pev.angles );
				pHurt.pev.punchangle.x = 15;
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 100 + g_Engine.v_up * 50;
				pHurt.TakeDamage( pev, pev, CYBERFRANKLIN_DAMAGE_KICK, DMG_CLUB );
			}
		}
		break;
		
		case CYBERFRANKLIN_AE_RELOAD:
		case CYBERFRANKLIN_AE_GREN_TOSS:
		case CYBERFRANKLIN_AE_GREN_LAUNCH:
		case CYBERFRANKLIN_AE_GREN_DROP:
			// Unused by Cyber-Franklin
			break;
			
		default:
			BaseClass.HandleAnimEvent( pEvent );
			break;
		}
	}
	
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType)
	{	
		if( pevAttacker is null )
			return 0;

		CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pevAttacker );

		if( self.CheckAttacker( pAttacker ) )
			return 0;

		return BaseClass.TakeDamage(pevInflictor, pevAttacker, flDamage, bitsDamageType);
	}
	
	void PainSound()
	{
		if (g_Engine.time < m_painTime)
			return;
		
		m_painTime = g_Engine.time + Math.RandomFloat(0.5, 0.75);
		switch (Math.RandomLong(0,1))
		{
		case 0: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "hunger/franklin/pain1.wav", 1, ATTN_NORM, 0, PITCH_NORM); break;
		case 1: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "hunger/franklin/pain2.wav", 1, ATTN_NORM, 0, PITCH_NORM); break;
		}
	}
	
	void DeathSound()
	{
		switch (Math.RandomLong(0,2))
		{
		case 0: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "hunger/franklin/death1.wav", 1, ATTN_NORM, 0, PITCH_NORM); break;
		case 1: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "hunger/franklin/death2.wav", 1, ATTN_NORM, 0, PITCH_NORM); break;
		case 2: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "hunger/franklin/death3.wav", 1, ATTN_NORM, 0, PITCH_NORM); break;
		}
	}
	
	void TraceAttack( entvars_t@ pevAttacker, float flDamage, Vector vecDir, TraceResult& in ptr, int bitsDamageType)
	{
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( ptr.pHit );
		
		if ( ptr.iHitgroup == 10 && (bitsDamageType & (DMG_BULLET | DMG_SLASH | DMG_CLUB)) != 0 )
		{
			// hit armor
			if ( pev.dmgtime != g_Engine.time || (Math.RandomLong(0,10) < 1) )
			{
				g_Utility.Ricochet( ptr.vecEndPos, Math.RandomFloat( 1, 2) );
				pev.dmgtime = g_Engine.time;
			}

			if ( Math.RandomLong( 0, 1 ) == 0 )
			{
				Vector vecTracerDir = vecDir;

				vecTracerDir.x += Math.RandomFloat( -0.3, 0.3 );
				vecTracerDir.y += Math.RandomFloat( -0.3, 0.3 );
				vecTracerDir.z += Math.RandomFloat( -0.3, 0.3 );

				vecTracerDir = vecTracerDir * -512;
				
				NetworkMessage message( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, ptr.vecEndPos );
					message.WriteByte(TE_TRACER);
					message.WriteCoord(ptr.vecEndPos.x);
					message.WriteCoord(ptr.vecEndPos.y);
					message.WriteCoord(ptr.vecEndPos.z);
					message.WriteCoord(vecTracerDir.x);
					message.WriteCoord(vecTracerDir.y);
					message.WriteCoord(vecTracerDir.z);
				message.End();
			}

			flDamage -= 20;
			if (flDamage <= 0)
				flDamage = 0.1;// don't hurt the monster much, but allow bits_COND_LIGHT_DAMAGE to be generated
		}
		else
		{
			g_Utility.BloodStream(Vector( self.pev.origin ), ptr.vecEndPos, self.BloodColor(), int( flDamage ) );
			self.TraceBleed( flDamage, vecDir, ptr, bitsDamageType );
		}

		g_WeaponFuncs.ClearMultiDamage();
		pEntity.TraceAttack( pevAttacker, flDamage, vecDir, ptr, bitsDamageType );
		g_WeaponFuncs.ApplyMultiDamage( pevAttacker, self.pev );
	}
	
	Schedule@ GetScheduleOfType( int Type )
	{		
		Schedule@ psched;

		switch( Type )
		{
		// Hook these to make a looping schedule
		case SCHED_TARGET_FACE:
			@psched = BaseClass.GetScheduleOfType(Type);
			
			if (psched is Schedules::slIdleStand)
				return slFaceTarget;	// override this for different target face behavior
			else
				return psched;

		case SCHED_IDLE_STAND:
			@psched = BaseClass.GetScheduleOfType(Type);

			if (psched is Schedules::slIdleStand)		
				return slIdleStand;// just look straight ahead.
			else
				return psched;	
		}

		return BaseClass.GetScheduleOfType( Type );
	}
	
	Schedule@ GetSchedule( void )
	{
		if ( self.HasConditions( bits_COND_ENEMY_DEAD ) )
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "svencoop2/weirdlaugh1.wav", 1, ATTN_NORM, 0, PITCH_NORM);

		switch( self.m_MonsterState )
		{
		case MONSTERSTATE_COMBAT:
			{
				// dead enemy
				if ( self.HasConditions( bits_COND_ENEMY_DEAD ) )				
					return BaseClass.GetSchedule();// call base class, all code to handle dead enemies is centralized there.

				// always act surprized with a new enemy
				if ( self.HasConditions( bits_COND_NEW_ENEMY ) && self.HasConditions( bits_COND_LIGHT_DAMAGE) )
					return self.GetScheduleOfType( SCHED_SMALL_FLINCH );
					
				if ( self.HasConditions( bits_COND_HEAVY_DAMAGE ) )
					return self.GetScheduleOfType( SCHED_TAKE_COVER_FROM_ENEMY );
					
				if ( self.HasConditions( bits_COND_CAN_MELEE_ATTACK1 ) )
					return self.GetScheduleOfType( SCHED_MELEE_ATTACK1 );
			}
			break;

		case MONSTERSTATE_ALERT:	
			{
				if ( self.HasConditions(bits_COND_LIGHT_DAMAGE | bits_COND_HEAVY_DAMAGE) )
					return self.GetScheduleOfType( SCHED_SMALL_FLINCH ); // flinch if hurt
			}
			break;
		}
		
		return BaseClass.GetSchedule();
	}
}

array<ScriptSchedule@>@ monster_th_cyberfranklin_schedules;

ScriptSchedule slFaceTarget(
	//bits_COND_CLIENT_PUSH	|
	bits_COND_NEW_ENEMY		|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND ,
	
	bits_COND_CAN_MELEE_ATTACK1 |
	
	bits_SOUND_DANGER,
	"FaceTarget" );
	
ScriptSchedule slIdleStand(
	bits_COND_NEW_ENEMY		|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND	|
	bits_COND_SMELL,
	
	bits_COND_CAN_MELEE_ATTACK1 |

	bits_SOUND_COMBAT		|// sound flags - change these, and you'll break the talking code.	
	bits_SOUND_DANGER		|
	bits_SOUND_MEAT			|// scents
	bits_SOUND_CARCASS		|
	bits_SOUND_GARBAGE,
	"IdleStand" );

void InitSchedules()
{
	slFaceTarget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );
	slFaceTarget.AddTask( ScriptTask(TASK_FACE_TARGET) );
	slFaceTarget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );
	slFaceTarget.AddTask( ScriptTask(TASK_SET_SCHEDULE, float(SCHED_TARGET_CHASE)) );
	
	slIdleStand.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slIdleStand.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );
	slIdleStand.AddTask( ScriptTask(TASK_WAIT, 2) );
	//slIdleStand.AddTask( ScriptTask(TASK_TLK_HEADRESET) );
	
	array<ScriptSchedule@> scheds = {slFaceTarget, slIdleStand};
	
	@monster_th_cyberfranklin_schedules = @scheds;
}

void Register()
{
	// Register Franklin's custom hornet
	FranklinHornet::Register();
	// Initialize schedules, so the main script does not have to take care of this
	InitSchedules();
	// Finally register Franklin's entity
	g_CustomEntityFuncs.RegisterCustomEntity( "CyberFranklin::monster_th_cyberfranklin", "monster_th_cyberfranklin" );
}

} // end of namespace
