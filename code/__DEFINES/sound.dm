//max channel is 1024. Only go lower from here, because byond tends to pick the first available channel to play sounds on
#define CHANNEL_LOBBYMUSIC 1024
#define CHANNEL_ADMIN 1023
#define CHANNEL_VOX 1022
#define CHANNEL_JUKEBOX 1021
#define CHANNEL_HEARTBEAT 1020 //sound channel for heartbeats
#define CHANNEL_BOSS_MUSIC 1019
#define CHANNEL_AMBIENCE 1018
#define CHANNEL_BUZZ 1017
#define CHANNEL_TRAITOR 1016
#define CHANNEL_CHARGED_SPELL 1015
#define CHANNEL_ELEVATOR 1014
#define CHANNEL_ESCAPEMENU 1013
//THIS SHOULD ALWAYS BE THE LOWEST ONE!
//KEEP IT UPDATED
#define CHANNEL_HIGHEST_AVAILABLE 1012

#define MAX_INSTRUMENT_CHANNELS (128 * 6)

/// This is the lowest volume that can be used by playsound otherwise it gets ignored
/// Most sounds around 10 volume can barely be heard. Almost all sounds at 5 volume or below are inaudible
/// This is to prevent sound being spammed at really low volumes due to distance calculations
/// Recommend setting this to anywhere from 10-3 (or 0 to disable any sound minimum volume restrictions)
/// Ex. For a 70 volume sound, 17 tile range, 3 exponent, 2 falloff_distance:
/// Setting SOUND_AUDIBLE_VOLUME_MIN to 0 for the above will result in 17x17 radius (289 turfs)
/// Setting SOUND_AUDIBLE_VOLUME_MIN to 5 for the above will result in 14x14 radius (196 turfs)
/// Setting SOUND_AUDIBLE_VOLUME_MIN to 10 for the above will result in 11x11 radius (121 turfs)
#define SOUND_AUDIBLE_VOLUME_MIN 3

/* Calculates the max distance of a sound based on audible volume
 *
 * Note - you should NEVER pass in a volume that is lower than SOUND_AUDIBLE_VOLUME_MIN otherwise distance will be insanely large (like +250,000)
 *
 * Arguments:
 * * volume: The initial volume of the sound being played
 * * max_distance: The range of the sound in tiles (technically not real max distance since the furthest areas gets pruned due to SOUND_AUDIBLE_VOLUME_MIN)
 * * falloff_distance: Distance at which falloff begins. Sound is at peak volume (in regards to falloff) aslong as it is in this range.
 * * falloff_exponent: Rate of falloff for the audio. Higher means quicker drop to low volume. Should generally be over 1 to indicate a quick dive to 0 rather than a slow dive.
 * Returns: The max distance of a sound based on audible volume range
 */
#define CALCULATE_MAX_SOUND_AUDIBLE_DISTANCE(volume, max_distance, falloff_distance, falloff_exponent)\
	floor(((((-(max(max_distance - falloff_distance, 0) ** (1 / falloff_exponent)) / volume) * (SOUND_AUDIBLE_VOLUME_MIN - volume)) ** falloff_exponent) + falloff_distance))

/* Calculates the volume of a sound based on distance
 *
 * https://www.desmos.com/calculator/sqdfl8ipgf
 *
 * Arguments:
 * * volume: The initial volume of the sound being played
 * * distance: How far away the sound is in tiles from the source
 * * falloff_distance: Distance at which falloff begins. Sound is at peak volume (in regards to falloff) aslong as it is in this range.
 * * falloff_exponent: Rate of falloff for the audio. Higher means quicker drop to low volume. Should generally be over 1 to indicate a quick dive to 0 rather than a slow dive.
 * Returns: The max distance of a sound based on audible volume range
 */
#define CALCULATE_SOUND_VOLUME(volume, distance, max_distance, falloff_distance, falloff_exponent)\
	((max(distance - falloff_distance, 0) ** (1 / falloff_exponent)) / ((max(max_distance, distance) - falloff_distance) ** (1 / falloff_exponent)) * volume)

///Default range of a sound.
#define SOUND_RANGE 17
#define MEDIUM_RANGE_SOUND_EXTRARANGE -5
///default extra range for sounds considered to be quieter
#define SHORT_RANGE_SOUND_EXTRARANGE -9
///The range deducted from sound range for things that are considered silent / sneaky
#define SILENCED_SOUND_EXTRARANGE -11
///Percentage of sound's range where no falloff is applied
#define SOUND_DEFAULT_FALLOFF_DISTANCE 1 //For a normal sound this would be 1 tile of no falloff
///The default exponent of sound falloff
#define SOUND_FALLOFF_EXPONENT 6

#define SOUND_MINIMUM_PRESSURE 10

#define INTERACTION_SOUND_RANGE_MODIFIER -3
#define EQUIP_SOUND_VOLUME 30
#define LIQUID_SLOSHING_SOUND_VOLUME 10
#define PICKUP_SOUND_VOLUME 15
#define DROP_SOUND_VOLUME 20
#define YEET_SOUND_VOLUME 90
#define BLOCK_SOUND_VOLUME 70

#define AMBIENCE_GENERIC "generic"
#define AMBIENCE_HOLY "holy"
#define AMBIENCE_DANGER "danger"
#define AMBIENCE_RUINS "ruins"
#define AMBIENCE_ENGI "engi"
#define AMBIENCE_MINING "mining"
#define AMBIENCE_ICEMOON "icemoon"
#define AMBIENCE_MEDICAL "med"
#define AMBIENCE_VIROLOGY "viro"
#define AMBIENCE_SPOOKY "spooky"
#define AMBIENCE_SPACE "space"
#define AMBIENCE_MAINT "maint"
#define AMBIENCE_AWAY "away"
#define AMBIENCE_REEBE "reebe" //unused
#define AMBIENCE_CREEPY "creepy" //not to be confused with spooky

//default byond sound environments
#define SOUND_ENVIRONMENT_NONE -1
#define SOUND_ENVIRONMENT_GENERIC 0
#define SOUND_ENVIRONMENT_PADDED_CELL 1
#define SOUND_ENVIRONMENT_ROOM 2
#define SOUND_ENVIRONMENT_BATHROOM 3
#define SOUND_ENVIRONMENT_LIVINGROOM 4
#define SOUND_ENVIRONMENT_STONEROOM 5
#define SOUND_ENVIRONMENT_AUDITORIUM 6
#define SOUND_ENVIRONMENT_CONCERT_HALL 7
#define SOUND_ENVIRONMENT_CAVE 8
#define SOUND_ENVIRONMENT_ARENA 9
#define SOUND_ENVIRONMENT_HANGAR 10
#define SOUND_ENVIRONMENT_CARPETED_HALLWAY 11
#define SOUND_ENVIRONMENT_HALLWAY 12
#define SOUND_ENVIRONMENT_STONE_CORRIDOR 13
#define SOUND_ENVIRONMENT_ALLEY 14
#define SOUND_ENVIRONMENT_FOREST 15
#define SOUND_ENVIRONMENT_CITY 16
#define SOUND_ENVIRONMENT_MOUNTAINS 17
#define SOUND_ENVIRONMENT_QUARRY 18
#define SOUND_ENVIRONMENT_PLAIN 19
#define SOUND_ENVIRONMENT_PARKING_LOT 20
#define SOUND_ENVIRONMENT_SEWER_PIPE 21
#define SOUND_ENVIRONMENT_UNDERWATER 22
#define SOUND_ENVIRONMENT_DRUGGED 23
#define SOUND_ENVIRONMENT_DIZZY 24
#define SOUND_ENVIRONMENT_PSYCHOTIC 25
//If we ever make custom ones add them here
#define SOUND_ENVIROMENT_PHASED list(1.8, 0.5, -1000, -4000, 0, 5, 0.1, 1, -15500, 0.007, 2000, 0.05, 0.25, 1, 1.18, 0.348, -5, 2000, 250, 0, 3, 100, 63)

//"sound areas": easy way of keeping different types of areas consistent.
#define SOUND_AREA_STANDARD_STATION SOUND_ENVIRONMENT_PARKING_LOT
#define SOUND_AREA_LARGE_ENCLOSED SOUND_ENVIRONMENT_QUARRY
#define SOUND_AREA_SMALL_ENCLOSED SOUND_ENVIRONMENT_BATHROOM
#define SOUND_AREA_TUNNEL_ENCLOSED SOUND_ENVIRONMENT_STONEROOM
#define SOUND_AREA_LARGE_SOFTFLOOR SOUND_ENVIRONMENT_CARPETED_HALLWAY
#define SOUND_AREA_MEDIUM_SOFTFLOOR SOUND_ENVIRONMENT_LIVINGROOM
#define SOUND_AREA_SMALL_SOFTFLOOR SOUND_ENVIRONMENT_ROOM
#define SOUND_AREA_ASTEROID SOUND_ENVIRONMENT_CAVE
#define SOUND_AREA_SPACE SOUND_ENVIRONMENT_UNDERWATER
#define SOUND_AREA_LAVALAND SOUND_ENVIRONMENT_MOUNTAINS
#define SOUND_AREA_ICEMOON SOUND_ENVIRONMENT_CAVE
#define SOUND_AREA_WOODFLOOR SOUND_ENVIRONMENT_CITY


///Announcer audio keys
#define ANNOUNCER_AIMALF "announcer_aimalf"
#define ANNOUNCER_ALIENS "announcer_aliens"
#define ANNOUNCER_ANIMES "announcer_animes"
#define ANNOUNCER_GRANOMALIES "announcer_granomalies"
#define ANNOUNCER_INTERCEPT "announcer_intercept"
#define ANNOUNCER_IONSTORM "announcer_ionstorm"
#define ANNOUNCER_METEORS "announcer_meteors"
#define ANNOUNCER_OUTBREAK5 "announcer_outbreak5"
#define ANNOUNCER_OUTBREAK7 "announcer_outbreak7"
#define ANNOUNCER_POWEROFF "announcer_poweroff"
#define ANNOUNCER_POWERON "announcer_poweron"
#define ANNOUNCER_RADIATION "announcer_radiation"
#define ANNOUNCER_SHUTTLECALLED "announcer_shuttlecalled"
#define ANNOUNCER_SHUTTLEDOCK "announcer_shuttledock"
#define ANNOUNCER_SHUTTLERECALLED "announcer_shuttlerecalled"
#define ANNOUNCER_SPANOMALIES "announcer_spanomalies"

/// Global list of all of our announcer keys.
GLOBAL_LIST_INIT(announcer_keys, list(
	ANNOUNCER_AIMALF,
	ANNOUNCER_ALIENS,
	ANNOUNCER_ANIMES,
	ANNOUNCER_GRANOMALIES,
	ANNOUNCER_INTERCEPT,
	ANNOUNCER_IONSTORM,
	ANNOUNCER_METEORS,
	ANNOUNCER_OUTBREAK5,
	ANNOUNCER_OUTBREAK7,
	ANNOUNCER_POWEROFF,
	ANNOUNCER_POWERON,
	ANNOUNCER_RADIATION,
	ANNOUNCER_SHUTTLECALLED,
	ANNOUNCER_SHUTTLEDOCK,
	ANNOUNCER_SHUTTLERECALLED,
	ANNOUNCER_SPANOMALIES,
))

/// List of all of our sound keys.
#define SFX_BODYFALL "bodyfall"
#define SFX_BULLET_MISS "bullet_miss"
#define SFX_CAN_OPEN "can_open"
#define SFX_CLOWN_STEP "clown_step"
#define SFX_DESECRATION "desecration"
#define SFX_EXPLOSION "explosion"
#define SFX_EXPLOSION_CREAKING "explosion_creaking"
#define SFX_HISS "hiss"
#define SFX_HONKBOT_E "honkbot_e"
#define SFX_GOOSE "goose"
#define SFX_HULL_CREAKING "hull_creaking"
#define SFX_HYPERTORUS_CALM "hypertorus_calm"
#define SFX_HYPERTORUS_MELTING "hypertorus_melting"
#define SFX_IM_HERE "im_here"
#define SFX_LAW "law"
#define SFX_PAGE_TURN "page_turn"
#define SFX_PUNCH "punch"
#define SFX_REVOLVER_SPIN "revolver_spin"
#define SFX_RICOCHET "ricochet"
#define SFX_RUSTLE "rustle"
#define SFX_SHATTER "shatter"
#define SFX_SM_CALM "sm_calm"
#define SFX_SM_DELAM "sm_delam"
#define SFX_SPARKS "sparks"
#define SFX_SUIT_STEP "suit_step"
#define SFX_SWING_HIT "swing_hit"
#define SFX_TERMINAL_TYPE "terminal_type"
#define SFX_WARPSPEED "warpspeed"
#define SFX_CRUNCHY_BUSH_WHACK "crunchy_bush_whack"
#define SFX_TREE_CHOP "tree_chop"
#define SFX_ROCK_TAP "rock_tap"
#define SFX_SEAR "sear"
#define SFX_REEL "reel"
#define SFX_RATTLE "rattle"
#define SFX_PORTAL_ENTER "portal_enter"
#define SFX_PORTAL_CLOSE "portal_closed"
#define SFX_PORTAL_CREATED "portal_created"
#define SFX_SCREECH "screech"
#define SFX_TOOL_SWITCH "tool_switch"
#define SFX_KEYBOARD_CLICKS "keyboard_clicks"
#define SFX_STONE_DROP "stone_drop"
#define SFX_STONE_PICKUP "stone_pickup"
#define SFX_MUFFLED_SPEECH "muffspeech"
#define SFX_DEFAULT_FISH_SLAP "default_fish_slap"
#define SFX_ALT_FISH_SLAP "alt_fish_slap"
#define SFX_FISH_PICKUP "fish_pickup"
#define SFX_CAT_MEOW "cat_meow"
#define SFX_CAT_PURR "cat_purr"
#define SFX_LIQUID_POUR "liquid_pour"
#define SFX_SNORE_FEMALE "snore_female"
#define SFX_SNORE_MALE "snore_male"
#define SFX_PLASTIC_BOTTLE_LIQUID_SLOSH "plastic_bottle_liquid_slosh"
#define SFX_DEFAULT_LIQUID_SLOSH "default_liquid_slosh"
#define SFX_PLATE_ARMOR_RUSTLE "plate_armor_rustle"
#define SFX_PIG_OINK "pig_oink"
#define SFX_VISOR_UP "visor_up"
#define SFX_VISOR_DOWN "visor_down"
#define SFX_SIZZLE "sizzle"
#define SFX_GROWL "growl"
#define SFX_POLAROID "polaroid"
#define SFX_HALLUCINATION_TURN_AROUND "hallucination_turn_around"
#define SFX_HALLUCINATION_I_SEE_YOU "hallucination_i_see_you"
#define SFX_HALLUCINATION_OVER_HERE "hallucination_over_here"
#define SFX_HALLUCINATION_I_M_HERE "hallucination_i_m_here"
#define SFX_VOID_DEFLECT "void_deflect"
#define SFX_LOW_HISS "low_hiss"
#define SFX_INDUSTRIAL_SCAN "industrial_scan"
#define SFX_MALE_SIGH "male_sigh"
#define SFX_FEMALE_SIGH "female_sigh"
#define SFX_WRITING_PEN "writing_pen"
#define SFX_CLOWN_CAR_LOAD "clown_car_load"
#define SFX_SEATBELT_BUCKLE "buckle"
#define SFX_SEATBELT_UNBUCKLE "unbuckle"
#define SFX_HEADSET_EQUIP "headset_equip"
#define SFX_HEADSET_PICKUP "headset_pickup"
#define SFX_BANDAGE_BEGIN "bandage_begin"
#define SFX_BANDAGE_END "bandage_end"
#define SFX_CLOTH_DROP "cloth_drop"
#define SFX_CLOTH_PICKUP "cloth_pickup"
#define SFX_SUTURE_BEGIN "suture_begin"
#define SFX_SUTURE_CONTINUOUS "suture_continuous"
#define SFX_SUTURE_END "suture_end"
#define SFX_SUTURE_PICKUP "suture_pickup"
#define SFX_SUTURE_DROP "suture_drop"

// Standard is 44.1khz
#define MIN_EMOTE_PITCH 40000
#define MAX_EMOTE_PITCH 48000
// ~0.6 - 1.4 at 0.12
#define EMOTE_TTS_PITCH_MULTIPLIER 0.12
