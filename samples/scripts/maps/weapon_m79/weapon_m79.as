/**
>>>Credits<<<

->Model: Hellspike
->Textures: klla_syc3/flamshmizer
->Animations: Michael65
->Compile, Edits: Norman the Loli Pirate
->Colored Model: D.N.I.O. 071
->Sprites: Der Graue Fuchs
->Script author: KernCore
->Sounds: Resident Evil Cold Blood Team

* This script is a sample to be used in: https://github.com/baso88/SC_AngelScript/
* You're free to use this sample in any way you would like to
* Just remember to credit the people who worked to provide you this

**/

// Enum for each animation in the model
enum AS_M79_Animations
{
	M79_IDLE = 0,
	M79_SHOOT,
	M79_RELOAD,
	M79_DEPLOY,
	M79_HOLSTER
};

namespace M79
{ // Namespace start

// Check to see if we're using the colored view model
bool isColored = false; // Change this to true to use the colorful view model, false to use the default view model

// Models
const string M79_W_MODEL = "models/as_gl/w_m79.mdl"; // World
const string M79_V_MODEL = (isColored) ? "models/as_gl/colored/v_m79.mdl" : "models/as_gl/v_m79.mdl"; // View
const string M79_P_MODEL = "models/as_gl/p_m79.mdl"; // Player
const string M79_G_MODEL = "models/as_gl/40mm.mdl"; // Grenade
const string M79_A_MODEL = "models/as_gl/w_40mm_ammo.mdl"; // Ammo
// Sounds
const string M79_S_SHOOT = "weapons/m79/m79_fire.wav";

const int M79_DEFAULT_GIVE 	= 4;
const int M79_MAX_CLIP  	= 1;
const int M79_MAX_CARRY 	= 20;
const int M79_WEIGHT    	= 20;
const int M79_AMMO_GIVE 	= 2;

class weapon_m79 : ScriptBasePlayerWeaponEntity
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( M79_W_MODEL ) );

		self.m_iDefaultAmmo = M79_DEFAULT_GIVE;

		self.FallInit(); //get ready to fall
	}

	// Always precache the stuff you're going to use
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( M79_W_MODEL );
		g_Game.PrecacheModel( M79_V_MODEL );
		g_Game.PrecacheModel( M79_P_MODEL );
		g_Game.PrecacheModel( M79_G_MODEL );

		// Precache here, because there's no late precache
		g_Game.PrecacheModel( M79_A_MODEL );
		g_Game.PrecacheModel( "sprites/as_sample/weapon_M79.spr" );

		// Precaches the sound for the engine to use
		g_SoundSystem.PrecacheSound( "weapons/m79/m79_close.wav" );
		g_SoundSystem.PrecacheSound( M79_S_SHOOT );
		g_SoundSystem.PrecacheSound( "weapons/m79/m79_open.wav" );
		g_SoundSystem.PrecacheSound( "weapons/m79/m79_shellin.wav" );
		g_SoundSystem.PrecacheSound( "weapons/m79/m79_shellout.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );

		// Precaches the stuff for download
		g_Game.PrecacheGeneric( "sound/" + "weapons/m79/m79_close.wav" );
		g_Game.PrecacheGeneric( "sound/" + M79_S_SHOOT );
		g_Game.PrecacheGeneric( "sound/" + "weapons/m79/m79_open.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/m79/m79_shellin.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/m79/m79_shellout.wav" );
		g_Game.PrecacheGeneric( "sprites/" + "as_sample/M79_crosshair.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "as_sample/weapon_M79.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "as_sample/weapon_m79.txt" );
	}

	bool GetItemInfo( ItemInfo& out info ) // Weapon information goes here
	{
		info.iMaxAmmo1 	= M79_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= M79_MAX_CLIP;
		info.iSlot   	= 2;
		info.iPosition 	= 10;
		info.iFlags  	= 0;
		info.iWeight 	= M79_WEIGHT;
		return true;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) )
		{
			NetworkMessage m79( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				m79.WriteLong( g_ItemRegistry.GetIdForName("weapon_m79") ); // A better way than using self.m_iId
			m79.End();
			return true;
		}
		
		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( M79_V_MODEL ), self.GetP_Model( M79_P_MODEL ), M79_DEPLOY, "bow" );
		
			float deployTime = 1.03;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		self.SendWeaponAnim( M79_HOLSTER, 0, 0 );
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		// don't fire underwater/without having ammo loaded
		if( self.m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.0f;
			return;
		}

		self.m_pPlayer.m_iWeaponVolume 	= NORMAL_GUN_VOLUME;
		self.m_pPlayer.m_iWeaponFlash 	= BRIGHT_GUN_FLASH;

		// Notify the monsters about the grenade
		self.m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
		self.m_pPlayer.m_flStopExtraSoundTime = WeaponTimeBase() + 0.2;

		--self.m_iClip;
		self.m_pPlayer.pev.effects |= EF_MUZZLEFLASH; // Add muzzleflash

		self.m_pPlayer.pev.punchangle.x = -10.0; // Recoil

		// player "shoot" animation
		self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		// Custom Volume and Pitch
		g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, M79_S_SHOOT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	
		Math.MakeVectors( self.m_pPlayer.pev.v_angle + self.m_pPlayer.pev.punchangle );

		Vector vecOrigin;
		Vector vecDir = g_Engine.v_forward * 900; //800

		// we don't add in player velocity anymore.
		if( ( self.m_pPlayer.pev.button & IN_DUCK ) != 0 )
		{
			vecOrigin = self.m_pPlayer.pev.origin + g_Engine.v_forward * 16 + g_Engine.v_right * 6;
		}
		else
		{
			vecOrigin = self.m_pPlayer.pev.origin + g_Engine.v_forward * 16 + g_Engine.v_right * 6 + self.m_pPlayer.pev.view_ofs * 0.5;
		}

		// Handles the grenade as custom entity, and changes their model
		CBaseEntity@ gGrenade = g_EntityFuncs.ShootContact( self.m_pPlayer.pev, vecOrigin, vecDir );
		g_EntityFuncs.SetModel( gGrenade, M79_G_MODEL );
		gGrenade.pev.dmg = 115; // Custom damage

		// View model animation
		self.SendWeaponAnim( M79_SHOOT );

		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 1;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 1;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + 5; // Idle pretty soon after shooting.

		if( self.m_iClip == 0 && self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			self.m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
	}

	void Reload()
	{
		// if the mag = the max mag, return
		if( self.m_iClip == M79_MAX_CLIP )
			return;
		// if the reserve ammo pool = 0, return
		if( self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
			return;
		/**
		* Reloads the weapon with the following params:
		* >int Max clip;
		* >int Reload Animation;
		* >float Timing, the reload animation frames/fps;
		* >int bodygroups( only use if model has any bodygroups to be used). 
		**/
		self.DefaultReload( M79_MAX_CLIP, M79_RELOAD, 3.88, 0 );

		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		self.m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		self.SendWeaponAnim( M79_IDLE, 0, 0 );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( self.m_pPlayer.random_seed, 5, 6 ); // How much time to idle again
	}
}

// Ammo class
class M79Ammo : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, M79_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( M79_A_MODEL );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		int iGive;
		
		iGive = M79_AMMO_GIVE;
		
		if( pOther.GiveAmmo( iGive, "ammo_m79", M79_MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}
		return false;
	}
}

string GetM79WName()
{
	return "weapon_m79";
}

string GetM79AName()
{
	return "ammo_m79";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "M79::weapon_m79", GetM79WName() ); // Register the weapon entity
	g_CustomEntityFuncs.RegisterCustomEntity( "M79::M79Ammo", GetM79AName() ); // Register the ammo entity
	g_ItemRegistry.RegisterWeapon( GetM79WName(), "as_sample", GetM79AName() ); // Register the weapon
}

} // Namespace end
